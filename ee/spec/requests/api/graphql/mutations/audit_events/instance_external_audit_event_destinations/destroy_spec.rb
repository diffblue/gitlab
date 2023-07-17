# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroy an instance external audit event destination', feature_category: :audit_events do
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:destination) { create(:instance_external_audit_event_destination) }

  let(:input) do
    {
      id: GitlabSchema.id_from_object(destination).to_s
    }
  end

  let(:mutation) { graphql_mutation(:instance_external_audit_event_destination_destroy, input) }

  let(:mutation_response) { graphql_mutation_response(:instance_external_audit_event_destination_destroy) }

  let_it_be(:current_user) { admin }

  shared_examples 'a mutation that does not destroy a destination' do
    it 'does not destroy the destination' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }
        .not_to change { AuditEvents::ExternalAuditEventDestination.count }
    end

    it_behaves_like 'a mutation that returns top-level errors',
      errors: ['You do not have access to this mutation.']

    it 'does not audit the destruction' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }
        .not_to change { AuditEvent.count }
    end
  end

  context 'when feature is licensed' do
    before do
      stub_licensed_features(external_audit_events: true)
    end

    context 'when current user is an instance admin' do
      context 'when feature flag ff_external_audit_events is enabled' do
        it 'destroys the destination' do
          expect { post_graphql_mutation(mutation, current_user: admin) }
            .to change { AuditEvents::InstanceExternalAuditEventDestination.count }.by(-1)
        end

        it 'audits the destruction' do
          expect { post_graphql_mutation(mutation, current_user: admin) }
            .to change { AuditEvent.count }.by(1)

          expect(AuditEvent.last.details[:custom_message])
            .to eq("Destroy instance event streaming destination #{destination.destination_url}")
        end

        context 'when the destination id is invalid' do
          let_it_be(:invalid_destination_input) do
            {
              id: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/-1"
            }
          end

          let(:mutation) do
            graphql_mutation(:instance_external_audit_event_destination_destroy, invalid_destination_input)
          end

          it 'does not destroy the destination' do
            expect { post_graphql_mutation(mutation, current_user: admin) }
              .to change { AuditEvents::InstanceExternalAuditEventDestination.count }.by(0)
          end

          it_behaves_like 'a mutation that returns top-level errors',
            errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
        end
      end

      context 'when feature flag ff_external_audit_events is disabled' do
        before do
          stub_feature_flags(ff_external_audit_events: false)
        end

        it_behaves_like 'a mutation that does not destroy a destination'
      end
    end

    context 'when current user is not instance admin' do
      before do
        sign_in user
      end

      it_behaves_like 'a mutation that does not destroy a destination' do
        let_it_be(:current_user) { user }
      end
    end
  end

  context 'when feature is unlicensed' do
    before do
      stub_licensed_features(external_audit_events: false)
    end

    it_behaves_like 'a mutation that does not destroy a destination' do
      let_it_be(:current_user) { admin }
    end
  end
end
