# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'UserAddOnAssignmentCreate', feature_category: :seat_cost_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:namespace) { create(:group) }
  let_it_be(:add_on) { create(:gitlab_subscription_add_on) }
  let_it_be(:add_on_purchase) { create(:gitlab_subscription_add_on_purchase, namespace: namespace, add_on: add_on) }
  let_it_be(:assignee_user) { create(:user) }

  let(:user_id) { global_id_of(assignee_user) }
  let(:add_on_purchase_id) { global_id_of(add_on_purchase) }

  let(:input) do
    {
      user_id: user_id,
      add_on_purchase_id: add_on_purchase_id
    }
  end

  let(:queried_purchase_ids) { prepare_variables([add_on_purchase_id]) }

  let(:requested_fields) do
    <<-GQL
    errors
    addOnPurchase {
      id
      name
      purchasedQuantity
      assignedQuantity
    }
    user {
      name
      username

       addOnAssignments(addOnPurchaseIds: #{queried_purchase_ids}) {
        nodes {
          addOnPurchase {
            id
            name
            assignedQuantity
            purchasedQuantity
          }
        }
      }
    }
    GQL
  end

  let(:mutation) { graphql_mutation(:user_add_on_assignment_create, input, requested_fields) }
  let(:mutation_response) { graphql_mutation_response(:user_add_on_assignment_create) }
  let(:expected_response) do
    {
      "assignedQuantity" => 1,
      "id" => "gid://gitlab/GitlabSubscriptions::AddOnPurchase/#{add_on_purchase.id}",
      "purchasedQuantity" => 1,
      "name" => 'CODE_SUGGESTIONS'
    }
  end

  before_all do
    namespace.add_owner(current_user)
    namespace.add_developer(assignee_user)
  end

  shared_examples 'empty response' do
    it 'returns nil' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response).to be_nil
    end
  end

  shared_examples 'error response' do |error_message|
    it 'returns expected errors' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response["errors"]).to include(error_message)
      expect(mutation_response["addOnPurchase"]).to be_nil
      expect(mutation_response["user"]).to be_nil
    end
  end

  shared_examples 'success response' do
    it 'returns expected response' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response["errors"]).to eq([])
      expect(mutation_response["addOnPurchase"]).to eq(expected_response)
      expect(mutation_response["user"]).to include(
        'name' => assignee_user.name,
        'username' => assignee_user.username,
        'addOnAssignments' => { 'nodes' => [{ 'addOnPurchase' => expected_response }] }
      )
    end
  end

  it_behaves_like 'success response'

  context 'when feature flag hamilton_seat_management is disabled' do
    before do
      stub_feature_flags(hamilton_seat_management: false)
    end

    it_behaves_like 'empty response'
  end

  context 'when current_user is admin' do
    let(:current_user) { create(:admin) }

    it_behaves_like 'success response'
  end

  context 'when current_user is not owner or admin' do
    let(:current_user) { namespace.add_developer(create(:user)).user }

    it_behaves_like 'empty response'
  end

  context 'when the user is already assigned' do
    before do
      create(:gitlab_subscription_user_add_on_assignment, add_on_purchase: add_on_purchase, user: assignee_user)
    end

    it_behaves_like 'success response'
  end

  context 'when add_on_purchase_id does not exists' do
    let(:add_on_purchase_id) { global_id_of(id: 666, model_name: '::GitlabSubscriptions::AddOnPurchase') }

    it_behaves_like 'empty response'
  end

  context 'when ad_on_purchase has expired' do
    before do
      add_on_purchase.update!(expires_on: 1.day.ago)
    end

    it_behaves_like 'empty response'
  end

  context 'when user_id does not exists' do
    let(:user_id) { global_id_of(id: 666, model_name: '::User') }

    it_behaves_like 'empty response'
  end

  context 'when there are no free seats available' do
    before do
      add_on_purchase.assigned_users.create!(user: create(:user))
    end

    it_behaves_like 'error response', 'NO_SEATS_AVAILABLE'
  end

  context 'when user is guest' do
    let(:user_id) { global_id_of(namespace.add_guest(assignee_user).user) }

    it_behaves_like 'success response'
  end

  context 'when user does not belong to namespace' do
    let(:user_id) { global_id_of(create(:user)) }

    it_behaves_like 'error response', 'INVALID_USER_MEMBERSHIP'
  end

  context 'when user belongs to subgroup' do
    let(:subgroup) { create(:group, parent: namespace) }

    before do
      subgroup.add_developer(create(:user)) # rubocop: disable RSpec/BeforeAllRoleAssignment
    end

    it_behaves_like 'success response'
  end

  context 'when user belongs to project' do
    let_it_be(:project) { create(:project, namespace: namespace) }

    before do
      project.add_developer(assignee_user) # rubocop: disable RSpec/BeforeAllRoleAssignment
    end

    it_behaves_like 'success response'
  end

  context 'when user is member of shared group' do
    let(:invited_group) { create(:group) }

    before do
      invited_group.add_developer(assignee_user) # rubocop: disable RSpec/BeforeAllRoleAssignment

      create(:group_group_link, { shared_with_group: invited_group, shared_group: namespace })
    end

    it_behaves_like 'success response'
  end

  context 'when user is member of shared project' do
    let(:invited_group) { create(:group) }
    let_it_be(:project) { create(:project, namespace: namespace) }

    before do
      invited_group.add_developer(assignee_user) # rubocop: disable RSpec/BeforeAllRoleAssignment

      create(:project_group_link, project: project, group: invited_group)
    end

    it_behaves_like 'success response'
  end

  context 'when the query requests add on assignments that belong to a different namespace' do
    let_it_be(:additional_purchase) { create(:gitlab_subscription_add_on_purchase, add_on: add_on) }
    let(:queried_purchase_ids) { prepare_variables([add_on_purchase_id, global_id_of(additional_purchase)]) }

    before do
      create(:gitlab_subscription_user_add_on_assignment, add_on_purchase: additional_purchase, user: assignee_user)
    end

    it 'does not return the unauthorised assignments' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_data_at(:user_add_on_assignment_create, :user, :add_on_assignments, :nodes))
        .to match_array([{ 'addOnPurchase' => a_hash_including('id' => add_on_purchase_id.to_s) }])
    end

    it 'returns authorised assignments' do
      additional_purchase.namespace.add_owner(current_user)

      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_data_at(:user_add_on_assignment_create, :user, :add_on_assignments, :nodes))
        .to match_array([
          { 'addOnPurchase' => a_hash_including('id' => add_on_purchase_id.to_s) },
          { 'addOnPurchase' => a_hash_including('id' => global_id_of(additional_purchase).to_s) }
        ])
    end
  end

  context 'when there are multiple add-on assignments for the user' do
    let(:additional_purchase) { create(:gitlab_subscription_add_on_purchase, add_on: add_on) }
    let(:queried_purchase_ids) { prepare_variables([add_on_purchase_id, global_id_of(additional_purchase)]) }

    it "avoids N+1 database queries", :request_store do
      additional_purchase.namespace.add_owner(current_user)

      post_graphql_mutation(mutation, current_user: current_user)
      expect(graphql_data_at(:user_add_on_assignment_create, :user, :add_on_assignments, :nodes).count).to eq 1

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post_graphql_mutation(mutation, current_user: current_user)
      end

      create(:gitlab_subscription_user_add_on_assignment, add_on_purchase: additional_purchase, user: assignee_user)

      expect { post_graphql_mutation(mutation, current_user: current_user) }.to issue_same_number_of_queries_as(control)
      expect(graphql_data_at(:user_add_on_assignment_create, :user, :add_on_assignments, :nodes).count).to eq 2
    end
  end
end
