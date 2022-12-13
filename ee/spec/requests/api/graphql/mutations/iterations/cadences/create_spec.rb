# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating an iteration cadence', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:start_date) { Time.now.strftime('%F') }
  let(:attributes) do
    {
      title: 'title',
      start_date: start_date,
      duration_in_weeks: 1,
      iterations_in_advance: 1,
      automatic: true,
      active: false,
      roll_over: true,
      description: 'Iteration cadence description'
    }
  end

  let(:params) do
    {
      group_path: group.full_path
    }
  end

  let(:mutation) do
    graphql_mutation(:iteration_cadence_create, params.merge(attributes))
  end

  def mutation_response
    graphql_mutation_response(:iteration_cadence_create)
  end

  context 'when the user does not have permission' do
    before do
      stub_licensed_features(iterations: true)
    end

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not create iteration cadence' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change(Iterations::Cadence, :count)
    end
  end

  context 'when the user has permission' do
    before do
      group.add_developer(current_user)
    end

    context 'when iterations feature is disabled' do
      before do
        stub_licensed_features(iterations: false)
      end

      it_behaves_like 'a mutation that returns top-level errors',
                      errors: ['The resource that you are attempting to access does not '\
                 'exist or you don\'t have permission to perform this action']
    end

    context 'when iterations feature is enabled' do
      before do
        stub_licensed_features(iterations: true)
      end

      it 'creates the iteration cadence for a group' do
        post_graphql_mutation(mutation, current_user: current_user)

        iteration_cadence_hash = mutation_response['iterationCadence']
        aggregate_failures do
          expect(iteration_cadence_hash['title']).to eq('title')
          expect(iteration_cadence_hash['startDate']).to eq(start_date)
        end
      end

      context 'when creating a manual iteration cadence' do
        let(:attributes) { { title: 'automatic cadence', duration_in_weeks: 1, active: true, automatic: false } }

        it 'creates an iteration cadence' do
          expect { post_graphql_mutation(mutation, current_user: current_user) }.to change(Iterations::Cadence, :count).by(1)
        end
      end

      context 'when there are ActiveRecord validation errors' do
        let(:attributes) { { title: '', duration_in_weeks: 1, active: false, automatic: true } }

        it_behaves_like 'a mutation that returns errors in the response',
                        errors: ["Iterations in advance can't be blank", "Start date can't be blank", "Title can't be blank"]

        it 'does not create the iteration cadence' do
          expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change(Iterations::Cadence, :count)
        end
      end

      context 'when required arguments are missing' do
        let(:attributes) { { title: '', duration_in_weeks: 1, active: false } }

        it 'returns error about required argument' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect_graphql_errors_to_include(/was provided invalid value for automatic \(Expected value to not be null\)/)
        end

        it 'does not create the iteration cadence' do
          expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change(Iterations::Cadence, :count)
        end
      end
    end
  end
end
