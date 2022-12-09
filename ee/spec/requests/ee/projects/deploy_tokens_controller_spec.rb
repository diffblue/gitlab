# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DeployTokensController, feature_category: :projects do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:deploy_token) { create(:deploy_token, projects: [project]) }
  let_it_be(:params) do
    { id: deploy_token.id, namespace_id: project.namespace, project_id: project }
  end

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

  describe 'PUT /:project_path_with_namespace/-/deploy_tokens/:id/revoke' do
    subject(:put_revoke) do
      put "/#{project.path_with_namespace}/-/deploy_tokens/#{deploy_token.id}/revoke", params: params
    end

    it 'creates an audit event' do
      expect { put_revoke }.to change { AuditEvent.count }.by(1)

      expect(response).to redirect_to(project_settings_repository_path(project, anchor: 'js-deploy-tokens'))

      expected_message = <<~MESSAGE.squish
        Revoked project deploy token with name: #{deploy_token.name}
        with token_id: #{deploy_token.id} with scopes: #{deploy_token.scopes}.
      MESSAGE

      expect(AuditEvent.last.details[:custom_message]).to eq(expected_message)
      expect(AuditEvent.last.details).to include({
                                                   custom_message: expected_message,
                                                   action: :custom
                                                 })
    end

    before do
      stub_licensed_features(external_audit_events: true)
      group.external_audit_event_destinations.create!(destination_url: 'http://example.com')
    end

    it_behaves_like 'sends correct event type in audit event stream' do
      let_it_be(:event_type) { "deploy_token_revoked" }
    end
  end
end
