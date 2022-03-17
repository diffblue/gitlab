# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating an Iteration' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:cadence) { create(:iterations_cadence, group: group) }
  let_it_be(:iteration) { create(:iteration, group: group, iterations_cadence: cadence) }

  let(:start_date) { 1.day.from_now.strftime('%F') }
  let(:end_date) { 5.days.from_now.strftime('%F') }
  let(:attributes) do
    {
      title: 'title',
      description: 'some description',
      start_date: start_date,
      due_date: end_date
    }
  end

  let(:mutation) do
    params = { group_path: group.full_path, id: iteration.to_global_id.to_s }.merge(attributes)

    graphql_mutation(:update_iteration, params)
  end

  def mutation_response
    graphql_mutation_response(:update_iteration)
  end

  context 'when the user does not have permission' do
    before do
      stub_licensed_features(iterations: true)
      group.add_guest(current_user)
    end

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not update iteration' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change(iteration, :title)
    end
  end

  context 'when the user has permission' do
    before do
      group.add_developer(current_user)
    end

    context 'when iterations are disabled' do
      before do
        stub_licensed_features(iterations: false)
      end

      it_behaves_like 'a mutation that returns top-level errors' do
        let(:match_errors) do
          include('The resource that you are attempting to access does not '\
                  'exist or you don\'t have permission to perform this action')
        end
      end
    end

    context 'when iterations are enabled' do
      before do
        stub_licensed_features(iterations: true)
      end

      it 'updates the iteration', :aggregate_failures do
        post_graphql_mutation(mutation, current_user: current_user)

        # Let's check that the mutation response is good
        iteration_hash = mutation_response['iteration']
        expect(iteration_hash['description']).to eq('some description')
        expect(iteration_hash['startDate'].to_date).to eq(start_date.to_date)
        expect(iteration_hash['dueDate'].to_date).to eq(end_date.to_date)

        # Let's also check that the object was updated properly
        iteration.reload
        expect(iteration.description).to eq('some description')
        expect(iteration.start_date).to eq(start_date.to_date)
        expect(iteration.due_date).to eq(end_date.to_date)
      end

      context 'when updating title' do
        context 'with iterations_cadences FF enabled' do
          using RSpec::Parameterized::TableSyntax

          before do
            stub_feature_flags(iteration_cadences: true)
          end

          where(:title_before, :title_after, :expected_title) do
            nil   | "abc" | "abc"
            "abc" | "def" | "def"
          end

          with_them do
            let(:iteration) { create(:iteration, title: title_before, group: group, iterations_cadence: cadence) }
            let(:attributes) { { title: title_after } }

            it 'updates an iteration', :aggregate_failures do
              post_graphql_mutation(mutation, current_user: current_user)

              expect(mutation_response['iteration']['title']).to eq(expected_title)
              expect(iteration.reload.title).to eq(expected_title)
            end
          end
        end

        context 'with iterations_cadences FF disabled' do
          before do
            stub_feature_flags(iteration_cadences: false)
          end

          context 'when title is not given' do
            let(:attributes) { { title: "" } }

            it_behaves_like 'a mutation that returns top-level errors',
                            errors: ["Title can't be blank"]
          end
        end
      end

      context 'when updating dates' do
        let_it_be(:start_date) { 1.month.ago }
        let_it_be(:end_date) { 1.month.ago + 1.day }
        let_it_be(:attributes) { { start_date: start_date.strftime('%F') } }

        it 'updates the iteration with date in the past', :aggregate_failures do
          post_graphql_mutation(mutation, current_user: current_user)

          # Let's check that the mutation response is good
          iteration_hash = mutation_response['iteration']
          expect(iteration_hash['startDate'].to_date).to eq(start_date.to_date)

          # Let's also check that the object was updated properly
          iteration.reload
          expect(iteration.start_date).to eq(start_date.to_date)
        end

        context 'when another iteration with given dates overlap' do
          let_it_be(:another_iteration) { create(:iteration, group: group, iterations_cadence: cadence, start_date: start_date.strftime('%F'), due_date: end_date.strftime('%F') ) }

          it_behaves_like 'a mutation that returns errors in the response',
                          errors: ["Dates cannot overlap with other existing Iterations within this iterations cadence"]

          context 'with iterations_cadences FF disabled' do
            let_it_be(:attributes) { { title: 'iteration', start_date: start_date.strftime('%F') } }

            before do
              stub_feature_flags(iteration_cadences: false)
            end

            it_behaves_like 'a mutation that returns errors in the response',
              errors: ["Dates cannot overlap with other existing Iterations within this group"]
          end
        end
      end

      context 'when given a raw model id (backward compatibility)' do
        let(:attributes) { { id: iteration.id, title: 'title' } }

        it 'updates the iteration' do
          post_graphql_mutation(mutation, current_user: current_user)

          iteration_hash = mutation_response['iteration']
          expect(iteration_hash['title']).to eq('title')
          expect(iteration.reload.title).to eq('title')
        end
      end

      context 'when the list of attributes is empty' do
        let(:attributes) { {} }

        it_behaves_like 'a mutation that returns top-level errors',
                        errors: ['The list of iteration attributes is empty']

        it 'does not update the iteration' do
          expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change(iteration, :title)
        end
      end
    end
  end
end
