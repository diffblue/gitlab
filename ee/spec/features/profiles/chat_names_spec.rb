# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Chat', feature_category: :integrations do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'authorization page for GitLab for Slack app' do
    let(:params) do
      { team_id: 'T00', team_domain: 'my_chat_team', user_id: 'U01', user_name: 'my_chat_user' }
    end

    let!(:authorize_url) { ChatNames::AuthorizeUserService.new(params).execute }
    let(:authorize_path) { URI.parse(authorize_url).request_uri }

    before do
      visit authorize_path
    end

    shared_examples 'names the integration correctly' do
      specify do
        expect(page).to have_content(
          'An application called GitLab for Slack app is requesting access to your GitLab account'
        )
        expect(page).to have_content('Authorize GitLab for Slack app')
      end
    end

    include_examples 'names the integration correctly'

    context 'with Slack enterprise-enabled team' do
      let(:params) { super().merge(user_id: 'W01') }

      include_examples 'names the integration correctly'
    end
  end
end
