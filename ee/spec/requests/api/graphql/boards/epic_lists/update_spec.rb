# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update of an existing epic board list', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:board) { create(:epic_board, group: group) }
  let_it_be(:list) { create(:epic_list, epic_board: board, position: 0) }
  let_it_be(:list2) { create(:epic_list, epic_board: board) }
  let_it_be(:input) { { list_id: list.to_global_id.to_s, position: 1, collapsed: true } }

  let(:mutation) { graphql_mutation(:update_epic_board_list, input) }
  let(:mutation_response) { graphql_mutation_response(:update_epic_board_list) }

  before do
    stub_licensed_features(epics: true)
  end

  it_behaves_like 'a GraphQL request to update board list'
end
