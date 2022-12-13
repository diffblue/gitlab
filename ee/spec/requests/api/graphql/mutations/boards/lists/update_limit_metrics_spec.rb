# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update list limit metrics', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:board) { create(:board, group: group) }
  let_it_be(:user)  { create(:user) }
  let_it_be(:list)  { create(:list, board: board) }
  let_it_be(:forbidden_user) { create(:user) }

  let(:current_user) { user }

  let(:mutation_class) { Mutations::Boards::Lists::UpdateLimitMetrics }
  let(:mutation_name) { mutation_class.graphql_name }
  let(:mutation_result_identifier) { mutation_name.camelize(:lower) }

  before_all do
    group.add_maintainer(user)
  end

  context 'the current_user is not allowed to update the issue' do
    let(:current_user) { forbidden_user }

    it 'returns an error' do
      perform_mutation(build_mutation('all_metrics'))

      expect(graphql_errors).to include(a_hash_including('message' => "The resource that you are attempting to access does " \
       "not exist or you don't have permission to perform this action"))
    end
  end

  it 'returns an error if the list cannot be found' do
    list_gid = GlobalID.new(::Gitlab::GlobalId.build(model_name: 'List', id: 0))

    perform_mutation(build_mutation('all_metrics', list_id: list_gid.to_s))

    expect(graphql_errors).to include(a_hash_including('message' => "The resource that you are attempting to access does " \
     "not exist or you don't have permission to perform this action"))
  end

  context 'the list_id is not a valid ListID' do
    let(:mutation) { build_mutation('all_metrics', list_id: user.to_global_id.to_s) }

    it_behaves_like 'an invalid argument to the mutation', argument_name: :list_id
  end

  %w[all_metrics issue_count issue_weights].each do |metric|
    it "updates the list limit metrics for limit metric #{metric}" do
      perform_mutation(build_mutation(metric))

      expect(response).to have_gitlab_http_status(:success)

      expect(graphql_data).to include(
        mutation_result_identifier => include(
          'list' => include(
            'id' => eq(list.to_global_id.to_s),
            'limitMetric' => eq(metric.to_s),
            'maxIssueCount' => eq(3),
            'maxIssueWeight' => eq(42)
          )
        )
      )

      expect_list_update(list, metric: metric, count: 3, weight: 42)
    end
  end

  def list_update_params(metric)
    {
      list_id: list.to_global_id.to_s,
      limit_metric: metric,
      max_issue_count: 3,
      max_issue_weight: 42
    }
  end

  def perform_mutation(mutation)
    post_graphql_mutation(mutation, current_user: current_user)
  end

  def build_mutation(metric, additional_params = {})
    graphql_mutation(mutation_name, list_update_params(metric).merge(additional_params),
                     <<-QL.strip_heredoc
                       clientMutationId
                       list {
                         id, maxIssueCount, maxIssueWeight, limitMetric
                       }
                       errors
    QL
    )
  end

  def expect_list_update(list, metric:, count:, weight:)
    reloaded_list = list.reload

    expect(reloaded_list.limit_metric).to eq(metric)
    expect(reloaded_list.max_issue_count).to eq(count)
    expect(reloaded_list.max_issue_weight).to eq(weight)
  end
end
