# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.addOnPurchase', feature_category: :seat_cost_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:fields) { 'id purchasedQuantity assignedQuantity name' }
  let_it_be(:namespace) { create(:group) }
  let_it_be(:add_on) { create(:gitlab_subscription_add_on) }
  let_it_be(:add_on_purchase) { create(:gitlab_subscription_add_on_purchase, namespace: namespace, add_on: add_on) }

  let(:full_path) { namespace.full_path }
  let(:add_on_name) { add_on.name }

  let(:query) do
    graphql_query_for(
      :namespace, { full_path: full_path },
      query_graphql_field(
        :addOnPurchase, { addOnName: add_on_name },
        fields
      )
    )
  end

  let(:expected_response) do
    {
      "assignedQuantity" => 0,
      "id" => "gid://gitlab/GitlabSubscriptions::AddOnPurchase/#{add_on_purchase.id}",
      "purchasedQuantity" => 1,
      "name" => 'CODE_SUGGESTIONS'
    }
  end

  before_all do
    namespace.add_owner(current_user)
  end

  shared_examples 'empty response' do
    it 'returns nil' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['addOnPurchase']).to eq(nil)
    end
  end

  shared_examples 'success response' do
    it 'returns expected response' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['namespace']['addOnPurchase']).to eq(expected_response)
    end
  end

  it_behaves_like 'success response'

  context 'when namespace does not exists' do
    let(:full_path) { 'foo-bar-bazz' }

    it_behaves_like 'empty response'
  end

  context 'when namespace is not root namespace' do
    let(:full_path) { create(:group, :nested).full_path }

    it_behaves_like 'empty response'
  end

  context 'when add_on_name does not exists' do
    let(:add_on_name) { 'foobar' }

    it_behaves_like 'empty response'
  end

  context 'when current_user is not owner of namespace' do
    let(:current_user) { create(:user) }

    it_behaves_like 'empty response'
  end

  context 'when current_user is admin' do
    let(:current_user) { create(:admin) }

    it_behaves_like 'success response'
  end

  context 'when seats are assigned' do
    before do
      create(:gitlab_subscription_user_add_on_assignment, add_on_purchase: add_on_purchase)

      expected_response['assignedQuantity'] = 1
    end

    it_behaves_like 'success response'
  end

  context 'when add_on_name param is all caps' do
    let(:add_on_name) { 'CODE_SUGGESTIONS' }

    it_behaves_like 'success response'
  end

  context 'when no active add_on_purchase is present' do
    before do
      add_on_purchase.update!(expires_on: 1.day.ago)
    end

    it_behaves_like 'empty response'
  end

  context 'when expires_on date is today' do
    before do
      add_on_purchase.update!(expires_on: Date.current)
    end

    it_behaves_like 'success response'
  end
end
