# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting iterations', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:now) { Time.now }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:iteration_cadence1) { create(:iterations_cadence, group: group, active: true, duration_in_weeks: 1, title: 'one week iterations') }
  let_it_be(:iteration_cadence2) { create(:iterations_cadence, group: group, active: true, duration_in_weeks: 2, title: 'two week iterations') }

  before do
    group.add_developer(user)
  end

  describe 'query for iteration cadence' do
    shared_examples 'returns cadence by id' do
      it 'returns cadence' do
        post_graphql(iteration_cadence_by_id(group_or_project), current_user: user, variables: { id: cadence_id })

        expect_iteration_cadences_response(group_or_project.class.name.downcase.to_sym, expected_result)
      end
    end

    it 'returns all group cadences' do
      post_graphql(iteration_cadences_query(group), current_user: user)

      expect_iteration_cadences_response(:group, [iteration_cadence1, iteration_cadence2])
    end

    context 'by global id' do
      let(:cadence_id) { iteration_cadence1.to_global_id.to_s }
      let(:expected_result) { [iteration_cadence1] }

      context 'fetching cadences from group level' do
        let(:group_or_project) { group }

        it_behaves_like 'returns cadence by id'

        context 'from a different group' do
          let(:other_group) { create(:group) }
          let(:group_or_project) { other_group }
          let(:expected_result) { [] }

          it_behaves_like 'returns cadence by id'
        end
      end

      context 'fetching cadences from project level' do
        let(:group_or_project) { project }

        it_behaves_like 'returns cadence by id'
      end
    end
  end

  def iteration_cadences_query(group)
    <<~QUERY
      query {
        group(fullPath: "#{group.full_path}") {
          id,
          iterationCadences {
            nodes {
              id
            }
          }
        }
      }
    QUERY
  end

  def iteration_cadence_by_id(parent)
    if parent.is_a?(Group)
      <<~QUERY
        query($id: IterationsCadenceID!) {
          group(fullPath: "#{parent.full_path}") {
            id,
            iterationCadences(id: $id) {
              nodes {
                id
              }
            }
          }
        }
      QUERY
    else
      <<~QUERY
      query($id: IterationsCadenceID!) {
        project(fullPath: "#{parent.full_path}") {
          id,
          iterationCadences(id: $id) {
            nodes {
              id
            }
          }
        }
      }
      QUERY
    end
  end

  def expect_iteration_cadences_response(group_or_project, cadences)
    actual_cadences = graphql_data_at(group_or_project.to_sym, :iterationCadences, :nodes).map { |cadence| cadence['id'] }
    expected_cadences = cadences.map { |cadence| cadence.to_global_id.to_s }

    expect(actual_cadences).to contain_exactly(*expected_cadences)
    expect(graphql_errors).to be_nil
  end
end
