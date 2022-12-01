# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'epics swimlanes', :js, feature_category: :team_planning do
  include DragTo
  include MobileHelpers
  include BoardHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }

  let_it_be(:board) { create(:board, project: project) }
  let_it_be(:label) { create(:label, project: project, name: 'Label 1') }
  let_it_be(:list) { create(:list, board: board, label: label, position: 0) }

  let_it_be(:issue1) { create(:issue, project: project, labels: [label]) }

  let_it_be(:epic1) { create(:epic, group: group) }
  let_it_be(:epic2) { create(:epic, group: group) }

  before_all do
    project.add_maintainer(user)
    group.add_maintainer(user)
  end

  before do
    stub_feature_flags(apollo_boards: false)
    stub_licensed_features(epics: true, swimlanes: true)

    sign_in(user)
    load_board project_boards_path(project)
    load_epic_swimlanes
    load_unassigned_issues
  end

  context 'when no epic is displayed' do
    it('user can drag and drop between columns') do
      wait_for_board_cards_in_unassigned_lane(1, 1)

      epic_lanes = page.all(:css, '.board-epic-lane')
      expect(epic_lanes.length).to eq(0)

      drag(list_from_index: 1, list_to_index: 0)
      wait_for_board_cards_in_unassigned_lane(0, 1)
    end
  end

  context 'drag and drop issue' do
    let_it_be(:issue2) { create(:issue, project: project) }
    let_it_be(:issue3) { create(:issue, project: project, state: :closed) }
    let_it_be(:issue4) { create(:issue, project: project) }

    let_it_be(:epic_issue1) { create(:epic_issue, epic: epic1, issue: issue1) }
    let_it_be(:epic_issue2) { create(:epic_issue, epic: epic2, issue: issue2) }
    let_it_be(:epic_issue3) { create(:epic_issue, epic: epic2, issue: issue3) }

    it 'between epics' do
      wait_for_board_cards(1, 2)
      wait_for_board_cards_in_first_epic(0, 1)
      wait_for_board_cards_in_second_epic(1, 1)

      epic_lanes = page.all(:css, '.board-epic-lane')
      expect(epic_lanes.length).to eq(2)

      drag(list_from_index: 4, list_to_index: 1)

      epic_lanes = page.all(:css, '.board-epic-lane')
      expect(epic_lanes.length).to eq(1)

      wait_for_board_cards_in_first_epic(1, 1)
    end

    it 'from epic to unassigned issues lane' do
      wait_for_board_cards(1, 2)
      wait_for_board_cards_in_second_epic(1, 1)

      epic_lanes = page.all(:css, '.board-epic-lane')
      expect(epic_lanes.length).to eq(2)

      drag(list_from_index: 4, list_to_index: 7)

      epic_lanes = page.all(:css, '.board-epic-lane')
      expect(epic_lanes.length).to eq(1)

      wait_for_board_cards_in_unassigned_lane(1, 1)
    end

    it 'from unassigned issues lane to epic' do
      wait_for_board_cards(1, 2)
      wait_for_board_cards_in_unassigned_lane(0, 1)

      drag(list_from_index: 6, list_to_index: 3)

      wait_for_board_cards_in_second_epic(0, 1)
      wait_for_board_cards_in_unassigned_lane(0, 0)
    end

    it 'between lists within epic lane' do
      wait_for_board_cards(1, 2)
      wait_for_board_cards_in_first_epic(0, 1)

      drag(list_from_index: 0, list_to_index: 1)

      wait_for_board_cards(1, 1)
      wait_for_board_cards(2, 2)
      wait_for_board_cards_in_first_epic(0, 0)
      wait_for_board_cards_in_first_epic(1, 1)
    end

    it 'between lists within unassigned lane' do
      wait_for_board_cards(1, 2)
      wait_for_board_cards_in_second_epic(1, 1)
      wait_for_board_cards_in_unassigned_lane(0, 1)

      drag(list_from_index: 6, list_to_index: 7)

      wait_for_board_cards(1, 1)
      wait_for_board_cards(2, 2)
      wait_for_board_cards_in_unassigned_lane(0, 0)
      wait_for_board_cards_in_unassigned_lane(1, 1)
    end

    it 'between lists and epics' do
      inspect_requests(inject_headers: { 'X-GITLAB-DISABLE-SQL-QUERY-LIMIT' => 'https://gitlab.com/gitlab-org/gitlab/-/issues/323426' }) do
        wait_for_board_cards(1, 2)
        wait_for_board_cards_in_second_epic(1, 1)

        drag(list_from_index: 4, list_to_index: 2)

        wait_for_board_cards(2, 0)
        wait_for_board_cards(3, 2)
        wait_for_board_cards_in_first_epic(2, 2)
      end
    end
  end

  context 'drag and drop list' do
    let_it_be(:label2) { create(:label, project: project, name: 'Label 2') }
    let_it_be(:list2) { create(:list, board: board, label: label2, position: 1) }

    it 're-orders lists' do
      drag(list_from_index: 1, list_to_index: 2, selector: '.board-header')

      wait_for_requests

      expect(find_board_list_header(2)).to have_content(label2.title)
      expect(find_board_list_header(3)).to have_content(label.title)
      expect(list.reload.position).to eq(1)
      expect(list2.reload.position).to eq(0)
    end
  end

  def find_board_list_header(list_idx)
    find(".board:nth-child(#{list_idx}) [data-testid=\"board-list-header\"]")
  end

  def select_epics
    page.within('.board-swimlanes-toggle-wrapper') do
      page.find('.dropdown-toggle').click
      page.find('.dropdown-item', text: 'Epic').click

      wait_for_requests
    end
  end

  def drag(selector: '.board-cell', list_from_index: 0, from_index: 0, to_index: 0, list_to_index: 0, perform_drop: true)
    # ensure there is enough horizontal space for four boards
    resize_window(2000, 1200)

    drag_to(selector: selector,
            scrollable: '#board-app',
            list_from_index: list_from_index,
            from_index: from_index,
            to_index: to_index,
            list_to_index: list_to_index,
            perform_drop: perform_drop,
            extra_height: 50)
  end

  def wait_for_board_cards(board_number, expected_cards)
    page.within(find(".board-swimlanes-headers .board:nth-child(#{board_number})")) do
      expect(page.find('.board-header')).to have_content(expected_cards.to_s)
    end
  end

  def wait_for_board_cards_in_first_epic(board_number, expected_cards)
    page.within(all("[data-testid='board-epic-lane-issues']")[0]) do
      page.within(all(".board")[board_number]) do
        expect(page).to have_selector('.board-card', count: expected_cards)
      end
    end
  end

  def wait_for_board_cards_in_second_epic(board_number, expected_cards)
    page.within(all("[data-testid='board-epic-lane-issues']")[1]) do
      page.within(all(".board")[board_number]) do
        expect(page).to have_selector('.board-card', count: expected_cards)
      end
    end
  end

  def wait_for_board_cards_in_unassigned_lane(board_number, expected_cards)
    page.within(find("[data-testid='board-lane-unassigned-issues']")) do
      page.within(all(".board")[board_number]) do
        expect(page).to have_selector('.board-card', count: expected_cards)
      end
    end
  end
end
