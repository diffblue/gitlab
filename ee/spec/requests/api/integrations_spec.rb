# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::Integrations, feature_category: :integrations do
  let_it_be(:user) { create(:user) }

  let_it_be(:project) do
    create(:project, creator_id: user.id, namespace: user.namespace)
  end

  describe 'GitLab for Slack app integration' do
    before do
      project.create_gitlab_slack_application_integration

      stub_application_setting(
        slack_app_verification_token: 'token'
      )
    end

    it 'returns status 200' do
      post api('/slack/trigger'), params: { token: 'token', text: 'help' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['response_type']).to eq("ephemeral")
    end
  end
end
