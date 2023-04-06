# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable, product_group: :project_management do
    describe 'Sum of issues weights on issue board' do
      let(:label_board_list) do
        EE::Resource::Board::BoardList::Project::LabelBoardList.fabricate_via_api!
      end

      let(:label) { 'Testing' }
      let(:weight_for_issue_1) { 5 }
      let(:weight_for_issue_2) { 3 }

      before do
        Flow::Login.sign_in

        Resource::Issue.fabricate_via_api! do |issue|
          issue.project = label_board_list.project
          issue.labels = [label]
          issue.weight = weight_for_issue_1
        end

        Resource::Issue.fabricate_via_api! do |issue|
          issue.project = label_board_list.project
          issue.labels = [label]
          issue.weight = weight_for_issue_2
        end

        label_board_list.project.visit!
        Page::Project::Menu.perform(&:go_to_issue_boards)
      end

      it 'shows the sum of issues weights in the board list\'s header', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347969' do
        Page::Component::IssueBoard::Show.perform do |show|
          expect(show.boards_list_header_with_index(1)).to have_content(weight_for_issue_1 + weight_for_issue_2)
        end
      end
    end
  end
end
