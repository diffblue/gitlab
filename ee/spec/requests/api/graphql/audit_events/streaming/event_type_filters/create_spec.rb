# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create an audit event type filter', feature_category: :audit_events do
  include GraphqlHelpers

  let_it_be(:destination) { create(:external_audit_event_destination) }
  let_it_be(:event_type_filter) do
    create(:audit_events_streaming_event_type_filter, external_audit_event_destination: destination,
      audit_event_type: 'filter_1')
  end

  let_it_be(:user) { create(:user) }

  let(:current_user) { user }
  let(:group) { destination.group }
  let(:mutation_name) { :audit_events_streaming_destination_events_add }
  let(:mutation) { graphql_mutation(mutation_name, input) }
  let(:mutation_response) { graphql_mutation_response(mutation_name) }
  let(:input) { { destinationId: destination.to_gid, eventTypeFilters: ['filter_2'] } }

  context 'when unlicensed' do
    subject { post_graphql_mutation(mutation, current_user: user) }

    before do
      stub_licensed_features(external_audit_events: false)
    end

    it_behaves_like 'a mutation on an unauthorized resource'
  end

  context 'when licensed' do
    subject { post_graphql_mutation(mutation, current_user: user) }

    before do
      stub_licensed_features(external_audit_events: true)
    end

    context 'when current user is a group maintainer' do
      before do
        group.add_maintainer(user)
      end

      it_behaves_like 'a mutation that returns top-level errors',
        errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
    end

    context 'when current user is a group developer' do
      before do
        group.add_developer(user)
      end

      it_behaves_like 'a mutation that returns top-level errors',
        errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
    end

    context 'when current user is a group guest' do
      before do
        group.add_guest(user)
      end

      it_behaves_like 'a mutation that returns top-level errors',
        errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
    end

    context 'when current user is a group user' do
      before do
        group.add_owner(user)
      end

      it 'returns success response', :aggregate_failures do
        subject

        response = mutation_response
        expect(response["errors"]).to be_empty
        expect(response["eventTypeFilters"]).to eq(destination.event_type_filters.pluck(:audit_event_type))
      end

      context 'when event type filters in input in empty' do
        let(:input) { { destinationId: destination.to_gid, eventTypeFilters: [] } }

        it 'returns graphql error' do
          subject

          expect(graphql_errors).to include(a_hash_including('message' => 'event type filters must be present'))
        end
      end
    end
  end
end
