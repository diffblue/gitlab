# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupBoards, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:non_member) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:admin) { create(:user, :admin) }
  let_it_be(:board_parent) { create(:group, :public) }

  before_all do
    board_parent.add_owner(user)
  end

  let_it_be(:project) { create(:project, :public, namespace: board_parent ) }

  let_it_be(:dev_label) do
    create(:group_label, title: 'Development', color: '#FFAABB', group: board_parent)
  end

  let_it_be(:test_label) do
    create(:group_label, title: 'Testing', color: '#FFAACC', group: board_parent)
  end

  let_it_be(:ux_label) do
    create(:group_label, title: 'UX', color: '#FF0000', group: board_parent)
  end

  let_it_be(:dev_list) do
    create(:list, label: dev_label, position: 1)
  end

  let_it_be(:test_list) do
    create(:list, label: test_label, position: 2)
  end

  let_it_be(:milestone) { create(:milestone, group: board_parent) }
  let_it_be(:board_label) { create(:group_label, group: board_parent) }

  let_it_be(:board) do
    create(:board, group: board_parent,
                   milestone: milestone,
                   assignee: user,
                   label_ids: [board_label.id],
                   lists: [dev_list, test_list])
  end

  it_behaves_like 'group and project boards', "/groups/:id/boards", true
  it_behaves_like 'multiple and scoped issue boards', "/groups/:id/boards"

  describe 'POST /groups/:id/boards/:board_id/lists' do
    let(:url) { "/groups/#{board_parent.id}/boards/#{board.id}/lists" }

    it_behaves_like 'milestone board list'
    it_behaves_like 'assignee board list'
    it_behaves_like 'iteration board list' do
      let_it_be(:iteration) { create(:iteration, iterations_cadence: create(:iterations_cadence, group: board_parent)) }
    end
  end
end
