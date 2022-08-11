# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::SlackApplicationInstallService do
  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:project) { create(:project) }

  let(:integration) { project.gitlab_slack_application_integration }
  let(:installation) { integration.slack_integration }

  let(:slack_app_id) { 'A12345' }
  let(:slack_app_secret) { 'secret' }
  let(:oauth_code) { 'code' }
  let(:params) { { code: oauth_code } }
  let(:exchange_url) { described_class::SLACK_EXCHANGE_TOKEN_URL }
  let(:redirect_url) { Gitlab::Routing.url_helpers.slack_auth_project_settings_slack_url(project) }

  subject(:service) { described_class.new(project, user, params) }

  before do
    stub_application_setting(slack_app_id: slack_app_id, slack_app_secret: slack_app_secret)

    query = {
      client_id: slack_app_id,
      client_secret: slack_app_secret,
      code: oauth_code,
      redirect_uri: redirect_url
    }

    stub_request(:get, exchange_url)
      .with(query: query)
      .to_return(body: response.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  context 'Slack responds with an error' do
    let(:response) do
      {
        ok: false,
        error: 'something is wrong'
      }
    end

    it 'returns error result' do
      result = service.execute

      expect(result).to eq(message: 'Slack: something is wrong', status: :error)
    end
  end

  context 'Slack responds with an access token' do
    let(:response) do
      {
        ok: true,
        app_id: 'A12345',
        authed_user: { id: 'U12345' },
        scope: 'commands',
        token_type: 'bot',
        access_token: 'token-XXXXX',
        bot_user_id: 'U99999',
        team: { id: 'T12345', name: 'Team name' },
        enterprise: { is_enterprise_install: false }
      }
    end

    shared_examples 'success response' do
      it 'returns success result and creates all needed records' do
        result = service.execute

        expect(result).to eq(status: :success)
        expect(integration).to be_present
        expect(installation).to be_present
        expect(installation).to have_attributes(
          integration_id: integration.id,
          team_id: 'T12345',
          team_name: 'Team name',
          alias: project.full_path,
          user_id: 'U12345',
          bot_user_id: 'U99999',
          bot_access_token: 'token-XXXXX'
        )
      end
    end

    it_behaves_like 'success response'

    context 'when integration record already exists' do
      before do
        project.create_gitlab_slack_application_integration!
      end

      it_behaves_like 'success response'

      context 'when installation record already exists' do
        before do
          integration.create_slack_integration!(
            team_id: 'old value',
            team_name: 'old value',
            alias: 'old value',
            user_id: 'old value',
            bot_user_id: 'old value',
            bot_access_token: 'old value'
          )
        end

        it_behaves_like 'success response'
      end
    end
  end
end
