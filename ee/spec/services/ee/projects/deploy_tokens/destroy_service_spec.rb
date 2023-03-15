# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DeployTokens::DestroyService, feature_category: :continuous_delivery do
  let_it_be(:group) { create :group }
  let_it_be(:entity) { create(:project, group: group) }
  let_it_be(:deploy_token) { create(:deploy_token, projects: [entity]) }
  let_it_be(:user) { create(:user) }
  let_it_be(:deploy_token_params) { { token_id: deploy_token.id } }

  describe '#execute' do
    subject { described_class.new(entity, user, deploy_token_params).execute }

    it "destroys a token record and it's associated DeployToken" do
      expect { subject }.to change { ProjectDeployToken.count }.by(-1)
                                                               .and change { DeployToken.count }.by(-1)
    end

    it "creates an audit event" do
      expect { subject }.to change { AuditEvent.count }.by(1)

      expected_message = <<~MESSAGE.squish
        Destroyed project deploy token with name: #{deploy_token.name}
        with token_id: #{deploy_token.id} with scopes: #{deploy_token.scopes}.
      MESSAGE

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
      let_it_be(:event_type) { "deploy_token_destroyed" }
    end
  end
end
