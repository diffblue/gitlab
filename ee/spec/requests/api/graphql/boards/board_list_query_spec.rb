# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Querying a Board list', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:unknown_user) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:board) { create(:board, resource_parent: project) }
  let_it_be(:label) { create(:label, project: project, name: 'foo') }
  let_it_be(:list) { create(:list, board: board, label: label) }
  let_it_be(:iteration_cadence1) { create(:iterations_cadence, group: group) }
  let_it_be(:iteration_cadence2) { create(:iterations_cadence, group: group) }
  let_it_be(:current_iteration1) { create(:iteration, start_date: Date.yesterday, due_date: 1.day.from_now, iterations_cadence: iteration_cadence1) }
  let_it_be(:current_iteration2) { create(:iteration, start_date: Date.yesterday, due_date: 1.day.from_now, iterations_cadence: iteration_cadence2) }
  let_it_be(:issue1) { create(:issue, project: project, labels: [label], iteration: current_iteration1, health_status: :at_risk) }
  let_it_be(:issue2) { create(:issue, project: project, labels: [label], iteration: current_iteration2) }

  let(:current_user) { unknown_user }
  let(:filters) { {} }
  let(:query) do
    graphql_query_for(
      :board_list,
      { id: list.to_global_id.to_s, issueFilters: filters },
      %w[title issuesCount]
    )
  end

  subject { graphql_data['boardList'] }

  before_all do
    project.add_guest(guest)
  end

  before do
    post_graphql(query, current_user: current_user)
  end

  context 'when the user has access to the list' do
    let(:current_user) { guest }

    it_behaves_like 'a working graphql query'

    it { is_expected.to include({ 'issuesCount' => 2, 'title' => list.title }) }

    describe 'issue filters' do
      context 'when filtering by iteration arguments' do
        let(:filters) { { iterationWildcardId: :CURRENT, iterationCadenceId: [iteration_cadence2.to_global_id.to_s] } }

        it { is_expected.to include({ 'issuesCount' => 1, 'title' => list.title }) }
      end

      context 'when filtering by health_status argument' do
        let(:filters) { { health_status_filter: :ANY } }

        it { is_expected.to include({ 'issuesCount' => 1, 'title' => list.title }) }
      end

      context 'when filtering by negated health_status argument' do
        let(:filters) { { not: { health_status_filter: :atRisk } } }

        it { is_expected.to include({ 'issuesCount' => 1, 'title' => list.title }) }
      end
    end
  end

  context 'when the user does not have access to the list' do
    it { is_expected.to be_nil }
  end
end
