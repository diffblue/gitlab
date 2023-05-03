# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create an instance external audit event destination', feature_category: :audit_events do
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:destination_url) { 'https://gitlab.com/example/testendpoint' }

  let(:mutation) { graphql_mutation(:instance_external_audit_event_destination_create, input) }
  let(:mutation_response) { graphql_mutation_response(:instance_external_audit_event_destination_create) }

  let(:input) do
    {
      destinationUrl: destination_url
    }
  end

  let(:invalid_input) do
    {
      destinationUrl: 'ftp://gitlab.com/example/testendpoint'
    }
  end

  shared_examples 'a mutation that does not create a destination' do
    subject { post_graphql_mutation(mutation, current_user: current_user) }

    it 'does not create the destination' do
      expect { subject }
        .not_to change { AuditEvents::InstanceExternalAuditEventDestination.count }

      expect(graphql_data['instanceExternalAuditEventDestination']).to be_nil
    end

    it_behaves_like 'a mutation that returns top-level errors',
      errors: ['You do not have access to this mutation.']
  end

  context 'when feature is licensed' do
    before do
      stub_licensed_features(external_audit_events: true)
    end

    context 'when user is instance admin' do
      context 'when feature flag ff_external_audit_events is enabled' do
        subject { post_graphql_mutation(mutation, current_user: admin) }

        it 'creates the destination' do
          expect { subject }
            .to change { AuditEvents::InstanceExternalAuditEventDestination.count }.by(1)

          destination = AuditEvents::InstanceExternalAuditEventDestination.last
          expect(destination.destination_url).to eq(destination_url)
          expect(destination.verification_token).to be_present

          expect(mutation_response['errors']).to be_empty
          expect(mutation_response['instanceExternalAuditEventDestination']['destinationUrl']).to eq(destination_url)
          expect(mutation_response['instanceExternalAuditEventDestination']['id']).not_to be_empty
          expect(mutation_response['instanceExternalAuditEventDestination']['verificationToken']).not_to be_empty
        end

        context 'when destination is invalid' do
          let(:mutation) { graphql_mutation(:instance_external_audit_event_destination_create, invalid_input) }

          it 'returns correct errors' do
            expect { post_graphql_mutation(mutation, current_user: admin) }
              .not_to change { AuditEvents::InstanceExternalAuditEventDestination.count }

            expect(mutation_response['instanceExternalAuditEventDestination']).to be_nil
            expect(mutation_response['errors']).to contain_exactly(
              'Destination url is blocked: Only allowed schemes are http, https')
          end
        end
      end

      context 'when feature flag ff_external_audit_events is disabled' do
        before do
          stub_feature_flags(ff_external_audit_events: false)
        end

        it_behaves_like 'a mutation that does not create a destination' do
          let_it_be(:current_user) { admin }
        end
      end
    end

    context 'when current user is not instance admin' do
      it_behaves_like 'a mutation that does not create a destination' do
        let_it_be(:current_user) { user }
      end
    end
  end

  context 'when feature is unlicensed' do
    before do
      stub_licensed_features(external_audit_events: false)
    end

    context 'when feature flag ff_external_audit_events is enabled' do
      it_behaves_like 'a mutation that does not create a destination' do
        let_it_be(:current_user) { admin }
      end

      it_behaves_like 'a mutation that does not create a destination' do
        let_it_be(:current_user) { user }
      end
    end

    context 'when feature flag ff_external_audit_events is disabled' do
      before do
        stub_feature_flags(ff_external_audit_events: false)
      end

      it_behaves_like 'a mutation that does not create a destination' do
        let_it_be(:current_user) { admin }
      end

      it_behaves_like 'a mutation that does not create a destination' do
        let_it_be(:current_user) { user }
      end
    end
  end
end
