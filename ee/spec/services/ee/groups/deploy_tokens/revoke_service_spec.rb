# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::DeployTokens::RevokeService, feature_category: :subgroups do
  let_it_be(:entity) { create(:group) }
  let_it_be(:destination) { create(:external_audit_event_destination, group: entity) }
  let_it_be(:deploy_token) { create(:deploy_token, :group, groups: [entity]) }
  let_it_be(:user) { create(:user) }
  let_it_be(:deploy_token_params) { { id: deploy_token.id } }

  describe '#execute' do
    subject { described_class.new(entity, user, deploy_token_params).execute }

    it "creates an audit event" do
      expect { subject }.to change { AuditEvent.count }.by(1)

      expected_message = <<~MESSAGE.squish
        Revoked group deploy token with name: #{deploy_token.name}
        with token_id: #{deploy_token.id} with scopes: #{deploy_token.scopes}.
      MESSAGE

      expect(AuditEvent.last.details[:custom_message]).to eq(expected_message)
    end

    before do
      stub_licensed_features(external_audit_events: true)
    end

    it_behaves_like 'sends correct event type in audit event stream' do
      let_it_be(:event_type) { "group_deploy_token_revoked" }
    end

    context 'when group is a sub-group' do
      let_it_be(:parent_group) { create :group }
      let_it_be(:group) { create :group, parent: parent_group }
      let_it_be(:deploy_token) { create(:deploy_token, :group, groups: [group]) }
      let_it_be(:deploy_token_params) { { id: deploy_token.id } }

      subject { described_class.new(group, user, deploy_token_params).execute }

      before do
        group.add_owner(user)
      end

      include_examples 'sends streaming audit event'
    end
  end
end
