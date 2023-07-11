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

  let_it_be(:current_user) { user }
  let(:group) { destination.group }
  let_it_be(:mutation_name) { :audit_events_streaming_destination_events_add }
  let(:mutation) { graphql_mutation(mutation_name, input) }
  let(:mutation_response) { graphql_mutation_response(mutation_name) }
  let_it_be(:input) { { destinationId: destination.to_gid, eventTypeFilters: ['filter_2'] } }

  subject { post_graphql_mutation(mutation, current_user: user) }

  before do
    stub_licensed_features(external_audit_events: true)
  end

  context 'when current user is a group maintainer' do
    before do
      group.add_maintainer(user)
    end

    it_behaves_like 'a mutation on an unauthorized resource'
  end

  context 'when current user is a group developer' do
    before do
      group.add_developer(user)
    end

    it_behaves_like 'a mutation on an unauthorized resource'
  end

  context 'when current user is a group guest' do
    before do
      group.add_guest(user)
    end

    it_behaves_like 'a mutation on an unauthorized resource'
  end

  context 'when current user is a group owner' do
    before do
      group.add_owner(user)
    end

    include_examples 'create event type filters for external audit event destinations' do
      let_it_be(:non_existing_destination_id) do
        "gid://gitlab/AuditEvents::ExternalAuditEventDestination/#{non_existing_record_id}"
      end
    end
  end
end
