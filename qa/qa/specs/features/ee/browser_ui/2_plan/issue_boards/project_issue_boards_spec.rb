# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable, product_group: :project_management do
    describe 'Project issue boards' do
      before do
        Flow::Login.sign_in
      end

      let(:issue_title) { 'Issue to test board list' }

      context 'Label issue board' do
        let(:label) { 'Testing' }

        let(:label_board_list) do
          EE::Resource::Board::BoardList::Project::LabelBoardList.fabricate_via_api!
        end

        before do
          Resource::Issue.fabricate_via_api! do |issue|
            issue.project = label_board_list.project
            issue.title = issue_title
            issue.labels = [label]
          end

          go_to_project_board(label_board_list.project)
        end

        it 'shows the just created board with a "Testing" (label) list, and an issue on it', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347990' do
          Page::Component::IssueBoard::Show.perform do |show|
            expect(show.boards_dropdown).to have_content(label_board_list.board.name)
            expect(show.boards_list_header_with_index(1)).to have_content(label)
            expect(show.card_of_list_with_index(1)).to have_content(issue_title)
          end
        end
      end

      context 'Milestone issue board' do
        let(:milestone_board_list) do
          EE::Resource::Board::BoardList::Project::MilestoneBoardList.fabricate_via_api!
        end

        before do
          Resource::Issue.fabricate_via_api! do |issue|
            issue.project = milestone_board_list.project
            issue.title = issue_title
            issue.milestone = milestone_board_list.project_milestone
          end

          go_to_project_board(milestone_board_list.project)
        end

        it 'shows the just created board with a "1.0" (milestone) list, and an issue on it', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347953' do
          Page::Component::IssueBoard::Show.perform do |show|
            expect(show.boards_dropdown).to have_content(milestone_board_list.board.name)
            expect(show.boards_list_header_with_index(1)).to have_content('1.0')
            expect(show.card_of_list_with_index(1)).to have_content(issue_title)
          end
        end
      end

      context 'Assignee issue board' do
        before do
          @user = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)

          project = Resource::Project.fabricate_via_api! do |project|
            project.name = 'project-to-test-assignee-issue-board-list'
          end

          project.add_member(@user)

          Resource::Issue.fabricate_via_api! do |issue|
            issue.assignee_ids = [@user.id]
            issue.project = project
            issue.title = issue_title
          end

          @assignee_board_list = EE::Resource::Board::BoardList::Project::AssigneeBoardList.fabricate_via_api! do |board_list|
            board_list.assignee = @user
            board_list.project = project
          end

          go_to_project_board(project)
        end

        it 'shows the just created board with an assignee list, and an issue on it', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347991' do
          Page::Component::IssueBoard::Show.perform do |show|
            expect(show.boards_dropdown).to have_content(@assignee_board_list.board.name)
            expect(show.boards_list_header_with_index(1)).to have_content(@user.name)
            expect(show.card_of_list_with_index(1)).to have_content(issue_title)
          end
        end
      end

      private

      def go_to_project_board(project)
        project.visit!
        Page::Project::Menu.perform(&:go_to_issue_boards)
      end
    end
  end
end
