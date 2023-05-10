# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting iterations', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:now) { Time.now }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:iteration_cadence1) { create(:iterations_cadence, group: group, active: true, duration_in_weeks: 1, title: 'one week iterations') }
  let_it_be(:iteration_cadence2) { create(:iterations_cadence, group: group, active: true, duration_in_weeks: 2, title: 'two week iterations') }

  let_it_be(:current_group_iteration) { create(:iteration, iterations_cadence: iteration_cadence1, title: 'one test', start_date: 1.day.ago, due_date: 1.week.from_now) }
  let_it_be(:upcoming_group_iteration) { create(:iteration, iterations_cadence: iteration_cadence2, start_date: 1.day.from_now, due_date: 2.days.from_now) }
  let_it_be(:closed_group_iteration) { create(:iteration, iterations_cadence: iteration_cadence1, start_date: 3.weeks.ago, due_date: 1.week.ago) }

  before do
    group.add_maintainer(user)
  end

  describe 'query for iterations by timeframe' do
    context 'without start date' do
      it 'returns error' do
        post_graphql(iterations_query(group, "timeframe: { end: \"#{3.days.ago.to_date}\" }"), current_user: user)

        expect(graphql_errors).to include(a_hash_including('message' => "Argument 'start' on InputObject 'Timeframe' is required. Expected type Date!"))
      end
    end

    context 'without end date' do
      it 'returns error' do
        post_graphql(iterations_query(group, "timeframe: { start: \"#{3.days.ago.to_date}\" }"), current_user: user)

        expect(graphql_errors).to include(a_hash_including('message' => "Argument 'end' on InputObject 'Timeframe' is required. Expected type Date!"))
      end
    end

    context 'with start and end date' do
      it 'does not have errors' do
        post_graphql(iterations_query(group, "timeframe: { start: \"#{3.days.ago.to_date}\", end: \"#{3.days.from_now.to_date}\" }"), current_user: user)

        expect(graphql_errors).to be_nil
      end
    end
  end

  describe 'query for iterations by cadence' do
    context 'with multiple cadences' do
      context 'searching by cadence title or iteration title and sorting by cadence and due date ASC' do
        using RSpec::Parameterized::TableSyntax

        let_it_be(:past_iteration1) { create(:iteration, :with_due_date, iterations_cadence: iteration_cadence2, start_date: 4.weeks.ago) }
        let_it_be(:past_iteration2) { create(:iteration, :with_due_date, iterations_cadence: iteration_cadence2, start_date: 2.weeks.ago) }

        where(:search, :ordered_expected_iterations) do
          'two'       | lazy { [past_iteration1, past_iteration2, upcoming_group_iteration] }
          'iteration' | lazy { [closed_group_iteration, current_group_iteration, past_iteration1, past_iteration2, upcoming_group_iteration] }
        end

        with_them do
          let(:field_queries) { "search: \"#{search}\", in: [TITLE, CADENCE_TITLE], sort: CADENCE_AND_DUE_DATE_ASC" }

          it 'correctly returns ordered items' do
            post_graphql(iterations_query(group, field_queries), current_user: user)

            expect(actual_iterations).to eq(expected_iterations(ordered_expected_iterations))
          end
        end
      end

      it 'returns iterations' do
        post_graphql(iteration_cadence_query(group, [iteration_cadence1.to_global_id, iteration_cadence2.to_global_id]), current_user: user)

        expect_iterations_response(current_group_iteration, closed_group_iteration, upcoming_group_iteration)
      end
    end
  end

  describe 'query for iterations by state' do
    context 'with invalid state' do
      it 'returns empty iterations list' do
        post_graphql(iterations_query(group, "state: started"), current_user: user)

        expect(graphql_errors).to include(a_hash_including('message' =>
          "Argument 'state' on Field 'iterations' has an invalid value (started). Expected type 'IterationState'."))
      end
    end

    context 'with `current` state' do
      it 'returns `current` iteration' do
        post_graphql(iterations_query(group, "state: current"), current_user: user)

        expect_iterations_response(current_group_iteration)
      end
    end

    context 'with `closed` state' do
      it 'returns `closed` iteration' do
        post_graphql(iterations_query(group, "state: closed"), current_user: user)

        expect_iterations_response(closed_group_iteration)
      end

      context 'when sorting by cadence and due date DESC' do
        let_it_be(:another_closed_iteration) { create(:iteration, iterations_cadence: iteration_cadence1, start_date: 5.weeks.ago, due_date: 4.weeks.ago) }

        it 'returns `closed` iteration sorted by due date DESC' do
          post_graphql(iterations_query(group, "state: closed, sort: CADENCE_AND_DUE_DATE_DESC"), current_user: user)

          expect_iterations_response(another_closed_iteration, closed_group_iteration)
        end
      end
    end
  end

  def iteration_cadence_query(group, cadence_ids)
    cadence_ids_param = "[\"#{cadence_ids.join('","')}\"]"
    field_queries = "iterationCadenceIds: #{cadence_ids_param}"

    iterations_query(group, field_queries)
  end

  def iterations_query(group, field_queries)
    <<~QUERY
      query {
        group(fullPath: "#{group.full_path}") {
          id,
          iterations(#{field_queries}) {
            nodes {
              id
            }
          }
        }
      }
    QUERY
  end

  def actual_iterations
    graphql_data['group']['iterations']['nodes'].map { |iteration| iteration['id'] }
  end

  def expected_iterations(iterations)
    iterations.map { |iteration| iteration.to_global_id.to_s }
  end

  def expect_iterations_response(*iterations)
    expect(actual_iterations).to contain_exactly(*expected_iterations(iterations))
    expect(graphql_errors).to be_nil
  end
end
