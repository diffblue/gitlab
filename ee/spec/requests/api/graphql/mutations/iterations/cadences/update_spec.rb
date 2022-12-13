# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating an iteration cadence', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:iteration_cadence, refind: true) { create(:iterations_cadence, group: group) }

  let(:description) { 'updated cadence description' }
  let(:start_date) { Time.now.strftime('%F') }
  let(:attributes) do
    {
      title: 'title',
      start_date: start_date,
      duration_in_weeks: 1,
      iterations_in_advance: 1,
      active: false,
      roll_over: true,
      description: description
    }
  end

  let(:params) do
    { id: iteration_cadence.to_global_id.to_s }
  end

  let(:mutation) do
    graphql_mutation(:iteration_cadence_update, params.merge(attributes))
  end

  def mutation_response
    graphql_mutation_response(:iteration_cadence_update)
  end

  context 'when the user does not have permission' do
    before do
      stub_licensed_features(iterations: true)
    end

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not update the iteration cadence' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)

        iteration_cadence.reload
      end.to not_change(iteration_cadence, :title)
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

      it 'updates the iteration cadence', :aggregate_failures do
        post_graphql_mutation(mutation, current_user: current_user)

        iteration_cadence_hash = mutation_response['iterationCadence']
        expect(iteration_cadence_hash['title']).to eq('title')
        expect(iteration_cadence_hash['startDate'].to_date).to eq(start_date.to_date)
        expect(iteration_cadence_hash['durationInWeeks']).to eq(1)
        expect(iteration_cadence_hash['iterationsInAdvance']).to eq(1)
        expect(iteration_cadence_hash['automatic']).to eq(true)
        expect(iteration_cadence_hash['active']).to eq(false)
        expect(iteration_cadence_hash['rollOver']).to eq(true)
        expect(iteration_cadence_hash['description']).to eq(description)

        iteration_cadence.reload
        expect(iteration_cadence.title).to eq('title')
        expect(iteration_cadence.start_date).to eq(start_date.to_date)
        expect(iteration_cadence.duration_in_weeks).to eq(1)
        expect(iteration_cadence.iterations_in_advance).to eq(1)
        expect(iteration_cadence.automatic).to eq(true)
        expect(iteration_cadence.active).to eq(false)
        expect(iteration_cadence.roll_over).to eq(true)
        expect(iteration_cadence.description).to eq(description)
      end

      context 'when there are ActiveRecord validation errors' do
        let(:attributes) { { id: iteration_cadence.to_global_id.to_s, title: '' } }

        it_behaves_like 'a mutation that returns errors in the response',
                        errors: ["Title can't be blank"]

        it 'does not update the iteration cadence' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)

            iteration_cadence.reload
          end.not_to change(iteration_cadence, :title)
        end
      end

      context 'when required arguments are missing' do
        let(:params) { {} }

        it 'returns error about required argument' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect_graphql_errors_to_include(/was provided invalid value for id \(Expected value to not be null\)/)
        end
      end
    end
  end
end
