# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Set an Epic Subscription', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:epic) { create(:epic, group: group) }
  let(:subscribed_state) { true }

  let(:mutation) do
    params = { group_path: group.full_path, iid: epic.iid.to_s, subscribed_state: subscribed_state }

    graphql_mutation(:epic_set_subscription, params)
  end

  def mutation_response
    graphql_mutation_response(:epic_set_subscription)
  end

  context 'when epics feature is disabled' do
    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not subscribe user to the epic' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(epic.subscribed?(current_user)).to be_falsey
    end
  end

  context 'when epics feature is enabled' do
    before do
      stub_licensed_features(epics: true)
    end

    context 'when a user wants to subscribe to an epic' do
      it 'subscribes the user to the epic' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(epic.subscribed?(current_user)).to be_truthy
      end
    end

    context 'when a user wants to unsubscribe from an epic' do
      let(:subscribed_state) { false }

      it 'unsubscribes the user from the epic' do
        epic.subscribe(current_user)

        post_graphql_mutation(mutation, current_user: current_user)

        expect(epic.subscribed?(current_user)).to be_falsey
      end
    end
  end
end
