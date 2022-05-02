# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::SlackApplicationInstallService do
  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:project) { create(:project) }

  let(:slack_app_id) { 'A12345' }
  let(:slack_app_secret) { 'secret' }
  let(:oauth_code) { 'code' }
  let(:params) { { code: oauth_code, v2: 'true' } }
  let(:exchange_url) { described_class::SLACK_EXCHANGE_TOKEN_URL }
  let(:redirect_url) { Gitlab::Routing.url_helpers.slack_auth_project_settings_slack_url(project, v2: true) }

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

  def expect_slack_integration_is_created
    project.reload
    integration = project.gitlab_slack_application_integration
    installation = integration.slack_integration

    expect(integration).to be_present
    expect(installation).to be_present
    expect(installation).to have_attributes(
      service_id: integration.id,
      team_id: 'T12345',
      team_name: 'Team name',
      alias: project.full_path,
      user_id: 'U12345'
    )
  end

  def expect_chat_name_is_created
    expect(user.chat_names.first).to have_attributes(
      service_id: project.gitlab_slack_application_integration.id,
      team_id: 'T12345',
      team_domain: 'Team name',
      chat_id: 'U12345',
      chat_name: 'username',
      user: user
    )
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
        expect_slack_integration_is_created
        expect(ChatName.count).to be_zero
      end
    end

    shared_examples 'legacy response' do
      let(:params) { super().without(:v2) }
      let(:exchange_url) { described_class::SLACK_EXCHANGE_TOKEN_URL_LEGACY }
      let(:redirect_url) { super().delete_suffix('?v2=true') }
      let(:response) do
        {
          ok: true,
          access_token: 'token-XXXXX',
          user_id: 'U12345',
          user_name: 'username',
          team_id: 'T12345',
          team_name: 'Team name'
        }
      end

      it 'uses the legacy endpoint and creates all needed records' do
        result = service.execute

        expect(result).to eq(status: :success)
        expect_slack_integration_is_created
        expect_chat_name_is_created
      end
    end

    it_behaves_like 'success response'
    it_behaves_like 'legacy response'

    context 'when integration record already exists' do
      before do
        project.create_gitlab_slack_application_integration!
      end

      it_behaves_like 'success response'

      context 'when installation record already exists' do
        before do
          project.gitlab_slack_application_integration.create_slack_integration!(
            team_id: 'T12345',
            team_name: 'Team name',
            alias: project.full_path,
            user_id: 'U12345'
          )
        end

        it 'returns error and does not create any records' do
          expect { service.execute }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'when the FF :slack_app_use_v2_flow is disabled' do
      before do
        stub_feature_flags(slack_app_use_v2_flow: false)
      end

      it_behaves_like 'success response'
      it_behaves_like 'legacy response'
    end
  end
end
