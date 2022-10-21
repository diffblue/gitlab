# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable, product_group: :project_management do
    describe 'Group issue boards' do
      before do
        Flow::Login.sign_in

        group = QA::Resource::Group.fabricate_via_api!

        Page::Main::Menu.perform(&:go_to_groups)
        Page::Dashboard::Groups.perform do |groups|
          groups.click_group(group.path)
        end
        Page::Group::Menu.perform(&:go_to_issue_boards)
      end

      it 'creates a group issue board via the GUI', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347952' do
        Page::Component::IssueBoard::Show.perform do |show|
          new_board = "Board-#{SecureRandom.hex(4)}"

          show.create_new_board(new_board)

          expect(show.boards_dropdown).to have_content(new_board)
        end
      end
    end
  end
end
