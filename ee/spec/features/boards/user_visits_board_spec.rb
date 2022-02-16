# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User visits issue boards', :js do
  include BoardHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create_default(:group, :public) }
  let_it_be(:project) { create_default(:project, :public, group: group) }

  # TODO use 'let' when rspec-parameterized supports it.
  # https://gitlab.com/gitlab-org/gitlab/-/issues/329746
  assignee_username = 'root'
  label_name = 'foobar'
  scoped_label_name = 'workflow::in dev'
  issue_with_label = "issue with label"
  issue_with_scoped_label = "issue with scoped label"
  issue_with_assignee = "issue with assignee"
  issue_with_all_filters = "issue with all filters"

  let_it_be(:label) { create(:group_label, group: group, name: label_name) }
  let_it_be(:scoped_label) { create(:group_label, group: group, name: scoped_label_name) }
  let_it_be(:assignee) { create_default(:group_member, :maintainer, user: create(:user, username: assignee_username), group: group ).user }

  before_all do
    create_default(:issue, project: project, title: issue_with_label, labels: [label])
    create_default(:issue, project: project, title: issue_with_scoped_label, labels: [scoped_label])
    create_default(:issue, project: project, title: issue_with_assignee, assignees: [assignee])
    create_default(:issue, project: project, title: issue_with_all_filters, labels: [scoped_label, label], assignees: [assignee])
  end

  shared_examples "visiting board path" do
    before do
      visit board_path

      wait_for_requests

      if board_path.include?('group_by')
        load_unassigned_issues
      end
    end

    it 'displays all issues satisfiying filter params and correctly sets url params' do
      expect(query_strings(current_url)).to match_array(query_strings(expected_board_path))

      page.assert_selector('[data-testid="board_card"]', count: expected_issues.length)

      expected_issues.each { |issue_title| expect(page).to have_link issue_title }
    end
  end

  shared_examples "scoped to labels" do
    context "when board is scoped to labels" do
      before_all do
        clear_board_scope(board)
        board.update!(label_ids: [label.id, scoped_label.id])
      end

      label_params1 = { "label_name" => [label_name] }
      label_params2 = { "label_name" => [label_name, scoped_label_name] }
      assignee_param = { "assignee_username" => assignee_username }
      combined_params = label_params2.merge(assignee_param)

      where(:params, :expected_params, :expected_issues) do
        {}             | label_params2   | [issue_with_all_filters]
        label_params1  | label_params2   | [issue_with_all_filters]
        label_params2  | label_params2   | [issue_with_all_filters] # rubocop:disable Lint/BinaryOperatorWithIdenticalOperands
        assignee_param | combined_params | [issue_with_all_filters]
      end

      with_them do
        include_examples "visiting board path"
      end
    end
  end

  shared_examples "scoped to an assignee" do
    context "when board is scoped to an assignee" do
      before_all do
        clear_board_scope(board)
        board.update!(assignee: assignee)
      end

      scoped_label_param = { "label_name" => [scoped_label_name] }
      assignee_param = { "assignee_username" => assignee_username }
      combined_params = scoped_label_param.merge(assignee_param)

      where(:params, :expected_params, :expected_issues) do
        {}                 | assignee_param  | [issue_with_assignee, issue_with_all_filters]
        assignee_param     | assignee_param  | [issue_with_assignee, issue_with_all_filters]  # rubocop:disable Lint/BinaryOperatorWithIdenticalOperands
        scoped_label_param | combined_params | [issue_with_all_filters]
      end

      with_them do
        include_examples "visiting board path"
      end
    end
  end

  %w[project group].each do |workspace|
    context "visiting #{workspace} boards with search params" do
      let_it_be(:board) { workspace == "project" ? create(:board, project: project) : create(:board, group: group) }
      let_it_be(:backlog_list) { create(:backlog_list, board: board) }

      context 'in list view' do
        let(:board_path) { board_path_helper(workspace, params) }
        let(:expected_board_path) { board_path_helper(workspace, expected_params) }

        include_context "scoped to labels"
        include_context "scoped to an assignee"
      end

      context 'in epic swimlanes' do
        let(:board_path) { board_path_helper(workspace, params.merge({ "group_by" => "epic" })) }
        let(:expected_board_path) { board_path_helper(workspace, expected_params.merge({ "group_by" => "epic" })) }

        before do
          stub_licensed_features(epics: true, swimlanes: true)
        end

        include_context "scoped to labels"
        include_context "scoped to an assignee"
      end
    end
  end

  def board_path_helper(workspace, params)
    return project_boards_path(project, params) if workspace == "project"

    group_boards_path(group, params)
  end

  def query_strings(url)
    URI.decode_www_form_component(URI.parse(url).query).split('&')
  end

  def clear_board_scope(board)
    board.update!(label_ids: [], assignee: nil)
  end
end
