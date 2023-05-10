# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update an instance external audit event destination', feature_category: :audit_events do
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:destination) { create(:instance_external_audit_event_destination) }
  let_it_be(:destination_url) { 'https://example.com/test' }

  let(:input) do
    {
      id: GitlabSchema.id_from_object(destination).to_s,
      destinationUrl: destination_url
    }
  end

  let(:mutation) { graphql_mutation(:instance_external_audit_event_destination_update, input) }

  let(:mutation_response) { graphql_mutation_response(:instance_external_audit_event_destination_update) }

  shared_examples 'a mutation that does not update destination' do
    it 'does not update the destination' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }
        .not_to change { destination.reload.destination_url }

      expect(graphql_data['instanceExternalAuditEventDestination']).to be_nil
    end

    it_behaves_like 'a mutation that returns top-level errors',
      errors: ['You do not have access to this mutation.']
  end

  context 'when feature is licensed' do
    before do
      stub_licensed_features(external_audit_events: true)
    end

    context 'when current user is instance admin' do
      context 'when feature flag ff_external_audit_events is enabled' do
        it 'updates the destination with correct response' do
          expect { post_graphql_mutation(mutation, current_user: admin) }
            .to change { destination.reload.destination_url }.to("https://example.com/test")

          expect(mutation_response['errors']).to be_empty
          expect(mutation_response['instanceExternalAuditEventDestination']['destinationUrl']).to eq(destination_url)
          expect(mutation_response['instanceExternalAuditEventDestination']['id']).not_to be_empty
          expect(mutation_response['instanceExternalAuditEventDestination']['verificationToken']).not_to be_empty
        end
      end

      context 'when feature flag ff_external_audit_events is disabled' do
        before do
          stub_feature_flags(ff_external_audit_events: false)
        end

        it_behaves_like 'a mutation that does not update destination' do
          let_it_be(:current_user) { admin }
        end
      end
    end

    context 'when current user is not instance admin' do
      before do
        sign_in user
      end

      it_behaves_like 'a mutation that does not update destination' do
        let_it_be(:current_user) { user }
      end
    end
  end

  context 'when feature is unlicensed' do
    before do
      stub_licensed_features(external_audit_events: false)
    end

    it_behaves_like 'a mutation that does not update destination' do
      let_it_be(:current_user) { admin }
    end
  end
end
