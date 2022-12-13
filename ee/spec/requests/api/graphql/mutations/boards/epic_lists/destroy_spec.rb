# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroy an epic board list', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user, refind: true) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:board) { create(:epic_board, group: group) }
  let_it_be(:list, refind: true) { create(:epic_list, epic_board: board) }

  let(:variables) do
    {
      list_id: global_id_of(list)
    }
  end

  let(:mutation) do
    graphql_mutation(:epic_board_list_destroy, variables)
  end

  let(:mutation_response) { graphql_mutation_response(:epic_board_list_destroy) }

  before do
    stub_licensed_features(epics: true)
  end

  it_behaves_like 'board lists destroy request' do
    let(:klass) { Boards::EpicList }
  end
end
