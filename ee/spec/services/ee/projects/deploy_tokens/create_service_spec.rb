# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DeployTokens::CreateService, feature_category: :continuous_delivery do
  let_it_be(:group) { create :group }
  let_it_be(:entity) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }

  let(:deploy_token_params) { attributes_for(:deploy_token) }

  describe '#execute' do
    subject { described_class.new(entity, user, deploy_token_params).execute }

    before do
      stub_licensed_features(external_audit_events: true)
      group.external_audit_event_destinations.create!(destination_url: 'http://example.com')
    end

    context 'when the deploy token is valid' do
      it 'creates an audit event' do
        expect { subject }.to change { AuditEvent.count }.by(1)

        expected_message = <<~MESSAGE.squish
          Created project deploy token with name: #{subject[:deploy_token].name}
          with token_id: #{subject[:deploy_token].id} with scopes: #{subject[:deploy_token].scopes}.
        MESSAGE

        expect(AuditEvent.last.details).to include({
                                                     custom_message: expected_message,
                                                     action: :custom
                                                   })
      end

      it_behaves_like 'sends correct event type in audit event stream' do
        let_it_be(:event_type) { "deploy_token_created" }
      end
    end

    context 'when the deploy token is invalid' do
      let(:deploy_token_params) { attributes_for(:deploy_token, read_repository: false, read_registry: false, write_registry: false) }

      it 'creates an audit event' do
        expect { subject }.to change { AuditEvent.count }.by(1)

        expected_message = "Attempted to create project deploy token but failed with message: Scopes can't be blank"

        expect(AuditEvent.last.details).to include({
                                                     custom_message: expected_message,
                                                     action: :custom
                                                   })
      end

      it_behaves_like 'sends correct event type in audit event stream' do
        let_it_be(:event_type) { "deploy_token_creation_failed" }
      end
    end
  end
end
