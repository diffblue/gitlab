# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable, product_group: :project_management do
    describe 'Read-only board configuration' do
      let(:qa_user) do
        Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)
      end

      let(:label_board_list) do
        EE::Resource::Board::BoardList::Project::LabelBoardList.fabricate_via_api!
      end

      before do
        Flow::Login.sign_in

        label_board_list.project.add_member(qa_user, Resource::Members::AccessLevel::GUEST)

        Page::Main::Login.perform do |login|
          login.sign_out_and_sign_in_as user: qa_user
        end

        label_board_list.project.visit!
        Page::Project::Menu.perform(&:go_to_issue_boards)
      end

      it 'shows board configuration to user without edit permission', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347959' do
        Page::Component::IssueBoard::Show.perform do |show|
          show.click_boards_config_button

          expect(show.board_scope_modal).to be_visible
          expect(show).not_to have_modal_board_name_field
        end
      end
    end
  end
end
