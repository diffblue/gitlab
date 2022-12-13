# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroying an iteration cadence', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:iteration_cadence, refind: true) { create(:iterations_cadence, group: group) }

  let(:params) do
    { id: iteration_cadence.to_global_id.to_s }
  end

  let(:mutation) do
    graphql_mutation(:iteration_cadence_destroy, params)
  end

  def mutation_response
    graphql_mutation_response(:iteration_cadence_destroy)
  end

  context 'when the user does not have permission' do
    before do
      stub_licensed_features(iterations: true)
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when the user has permission' do
    before do
      group.add_developer(current_user)
    end

    context 'when iterations feature is disabled' do
      before do
        stub_licensed_features(iterations: false)
      end

      it_behaves_like 'a mutation that returns top-level errors', errors: [
        'The resource that you are attempting to access does not exist or you don\'t have permission to ' \
        'perform this action'
      ]
    end

    context 'when iterations feature is enabled' do
      before do
        stub_licensed_features(iterations: true)
      end

      it 'destroys the iteration cadence', :aggregate_failures do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change(Iterations::Cadence, :count).by(-1)

        expect(mutation_response).to include('group' => hash_including('id' => group.to_global_id.to_s))
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
