# frozen_string_literal: true

# Shared examples for creating event type filters for external audit event destinations
# It expects following parameters:
#   - current_user -> The user who has access for creating these filters, for example group owner or instance admin
#   - mutation -> graphql_mutation for the corresponding mutation
#   - mutation_response -> graphql_mutation_response for the corresponding mutation
#   - destination -> Object of external destination, can be a group or instance destination
#   - non_existing_destination_id - A string containing gid of destination with non existing record id
RSpec.shared_examples 'create event type filters for external audit event destinations' do
  subject { post_graphql_mutation(mutation, current_user: current_user) }

  context 'when unlicensed' do
    before do
      stub_licensed_features(external_audit_events: false)
    end

    it_behaves_like 'a mutation on an unauthorized resource'
  end

  context 'when licensed' do
    before do
      stub_licensed_features(external_audit_events: true)
    end

    it 'returns success response', :aggregate_failures do
      subject

      expect(mutation_response["errors"]).to be_empty
      expect(mutation_response["eventTypeFilters"]).to eq(destination.event_type_filters.pluck(:audit_event_type))
    end

    context 'when event type filters in input is empty' do
      let_it_be(:input) { { destinationId: destination.to_gid, eventTypeFilters: [] } }

      it 'returns graphql error' do
        subject

        expect(graphql_errors).to include(a_hash_including('message' => 'event type filters must be present'))
      end
    end

    context 'when destinationId is invalid' do
      let_it_be(:input) { { destinationId: non_existing_destination_id, eventTypeFilters: ["filter1"] } }

      it_behaves_like 'a mutation on an unauthorized resource'
    end
  end
end
