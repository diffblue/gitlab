# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable, product_group: :project_management do
    describe 'Group issue boards' do
      let(:board_1) { "Board-#{SecureRandom.hex(4)}" }
      let(:board_2) { "Board-#{SecureRandom.hex(4)}" }
      let(:board_3) { "Board-#{SecureRandom.hex(4)}" }

      let(:group) do
        QA::Resource::Group.fabricate_via_api!
      end

      before do
        Flow::Login.sign_in

        create_group_board(board_1)
        create_group_board(board_2)
        create_group_board(board_3)

        Page::Main::Menu.perform(&:go_to_groups)
        Page::Dashboard::Groups.perform do |groups|
          groups.click_group(group.path)
        end
        Page::Group::Menu.perform(&:go_to_issue_boards)
      end

      it 'shows multiple group boards in the boards dropdown menu', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347950' do
        Page::Component::IssueBoard::Show.perform do |show|
          show.click_boards_dropdown_button

          expect(show.boards_dropdown_content).to have_content(board_1)
          expect(show.boards_dropdown_content).to have_content(board_2)
          expect(show.boards_dropdown_content).to have_content(board_3)
        end
      end

      def create_group_board(name)
        QA::EE::Resource::Board::GroupBoard.fabricate_via_api! do |group_board|
          group_board.group = group
          group_board.name = name
        end
      end
    end
  end
end
