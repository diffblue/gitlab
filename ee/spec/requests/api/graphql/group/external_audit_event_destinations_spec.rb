# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a list of external audit event destinations for a group', feature_category: :audit_events do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:destination_1) { create(:external_audit_event_destination, group: group) }
  let_it_be(:destination_2) { create(:external_audit_event_destination, group: group) }

  let(:path) { %i[group external_audit_event_destinations nodes] }

  let!(:query) do
    graphql_query_for(
      :group, { full_path: group.full_path }, query_nodes(:external_audit_event_destinations)
    )
  end

  shared_examples 'a request that returns no destinations' do
    it 'returns no destinations' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(:group, :external_audit_event_destinations)).to be_nil
    end
  end

  context 'when authenticated as the group owner' do
    before do
      stub_licensed_features(external_audit_events: true)
      group.add_owner(current_user)
    end

    it 'returns the groups external audit event destinations' do
      post_graphql(query, current_user: current_user)

      verification_token_regex = /\A\w{24}\z/i

      expect(graphql_data_at(*path)).to contain_exactly(
        a_hash_including('destinationUrl' => destination_1.destination_url, 'verificationToken' => a_string_matching(verification_token_regex)),
        a_hash_including('destinationUrl' => destination_2.destination_url, 'verificationToken' => a_string_matching(verification_token_regex))
      )
    end
  end

  context 'when authenticated as a group maintainer' do
    before do
      stub_licensed_features(external_audit_events: true)
      group.add_maintainer(current_user)
    end

    it_behaves_like 'a request that returns no destinations'
  end

  context 'when authenticated as a group developer' do
    before do
      stub_licensed_features(external_audit_events: true)
      group.add_developer(current_user)
    end

    it_behaves_like 'a request that returns no destinations'
  end

  context 'when authenticated as a group guest' do
    before do
      stub_licensed_features(external_audit_events: true)
      group.add_guest(current_user)
    end

    it_behaves_like 'a request that returns no destinations'
  end

  context 'when not authenticated' do
    before do
      stub_licensed_features(external_audit_events: true)
    end

    let(:current_user) { nil }

    it_behaves_like 'a request that returns no destinations'
  end
end
