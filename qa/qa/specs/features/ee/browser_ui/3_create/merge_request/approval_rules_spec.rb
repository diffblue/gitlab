# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Approval rules', product_group: :code_review do
      let(:approver1) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1) }
      let(:approver2) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_2, Runtime::Env.gitlab_qa_password_2) }
      let(:project) do
        Resource::Project.fabricate_via_api! { |project| project.name = "approval-rules" }
      end

      def login(user = nil)
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform { |login| login.sign_in_using_credentials(user: user) }
      end

      before do
        project.add_member(approver1)
        project.group.add_member(approver2)

        Flow::Login.sign_in
      end

      after do
        # Cleanup so that retries can start fresh
        project&.group&.remove_member(approver2)
        project&.remove_via_api!
      end

      it 'allows multiple approval rules with users and groups', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347771' do
        # Create a merge request with 2 rules
        merge_request = Resource::MergeRequest.fabricate_via_browser_ui! do |resource|
          resource.title = 'Add a new feature'
          resource.description = 'Great feature, much approval'
          resource.project = project
          resource.approval_rules = [
            {
              name: "user",
              approvals_required: 1,
              users: [approver1]
            },
            {
              name: "group",
              approvals_required: 1,
              groups: [project.group]
            }
          ]
        end

        Page::MergeRequest::Show.perform do |show|
          expect(show.num_approvals_required).to eq(2)
          expect(show.approvals_required_from).to include("user", "group")
        end

        # As approver1, approve the MR
        Page::Main::Menu.perform(&:sign_out)
        login(approver1)

        merge_request.visit!

        Page::MergeRequest::Show.perform do |show|
          show.click_approve
        end

        # Confirm that an approval was granted but it is not yet fully approved
        Page::MergeRequest::Show.perform do |show|
          expect(show).not_to be_approved
          expect(show.approvals_required_from).to include("group")
          expect(show.approvals_required_from).not_to include("user")
        end

        # As approver2, approve the MR
        Page::Main::Menu.perform(&:sign_out)
        login(approver2)

        merge_request.visit!

        Page::MergeRequest::Show.perform do |show|
          show.click_approve
        end

        # Confirm that the MR is fully approved
        Page::MergeRequest::Show.perform do |show|
          expect(show).to be_approved
        end

        # Merge the MR as the original user
        Page::Main::Menu.perform(&:sign_out)
        login

        merge_request.visit!

        Page::MergeRequest::Show.perform do |show|
          show.merge!

          expect(show).to be_merged
        end
      end
    end
  end
end
