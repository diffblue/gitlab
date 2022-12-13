# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Boards::Create, feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user, reload: true) { create(:user) }
  let_it_be(:parent) { create(:group) }
  let_it_be(:iteration_cadence) { create(:iterations_cadence, group: parent) }

  let(:group_path) { parent.full_path }
  let(:name) { 'board name' }
  let(:params) do
    {
      group_path: group_path,
      name: name,
      iteration_cadence_id: iteration_cadence.to_global_id.to_s
    }
  end

  let(:mutation) { graphql_mutation(:create_board, params) }

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  def mutation_response
    graphql_mutation_response(:create_board)
  end

  it_behaves_like 'boards create mutation'

  context 'when the user has permission to create a board' do
    before do
      parent.add_maintainer(current_user)
    end

    it 'sets cadence_id on creation' do
      expect { subject }.to change(::Board, :count).by(1)

      created_board = ::Board.last

      expect(created_board.iteration_cadence).to eq(iteration_cadence)
    end
  end
end
