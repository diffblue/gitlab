# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Codeowners', product_group: :source_code do
      # Create one user to be the assigned approver and another user who will not be an approver
      let(:approver) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1) }
      let(:non_approver) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_2, Runtime::Env.gitlab_qa_password_2) }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = "assign-approvers"
          project.initialize_with_readme = true
        end
      end

      let(:branch_name) { 'protected-branch' }

      before do
        project.add_member(approver, Resource::Members::AccessLevel::DEVELOPER)
        project.add_member(non_approver, Resource::Members::AccessLevel::DEVELOPER)

        Flow::Login.sign_in

        project.visit!
      end

      it 'merge request assigns code owners as approvers', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347776' do
        # Commit CODEOWNERS to default branch
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add CODEOWNERS and test files'
          commit.add_files(
            [
              {
                file_path: 'CODEOWNERS',
                content: <<~CONTENT
                  CODEOWNERS @#{approver.username}
                CONTENT
              }
            ]
          )
        end

        # Create a projected branch that requires approval from code owners
        Resource::ProtectedBranch.fabricate_via_browser_ui! do |protected_branch|
          protected_branch.branch_name = branch_name
          protected_branch.project = project
          protected_branch.require_code_owner_approval = true
        end

        # Push a new CODEOWNERS file
        Resource::Repository::Push.fabricate! do |push|
          push.repository_http_uri = project.repository_http_location.uri
          push.branch_name = branch_name + '-patch'
          push.file_name = 'CODEOWNERS'
          push.file_content = <<~CONTENT
            CODEOWNERS @#{non_approver.username}
          CONTENT
        end

        # Create a merge request
        Resource::MergeRequest.fabricate! do |merge_request|
          merge_request.project = project
          merge_request.target_new_branch = false
          merge_request.source_branch = branch_name + '-patch'
          merge_request.target_branch = branch_name
          merge_request.no_preparation = true
        end.visit!

        # Check that the merge request assigns the original code owner as an
        # approver (because the current CODEOWNERS file in the default branch
        # doesn't have the new owner yet)
        Page::MergeRequest::Show.perform do |show|
          show.edit!
          approvers = show.approvers

          expect(approvers.size).to eq(1)
          expect(approvers).to include(approver.name)
          expect(approvers).not_to include(non_approver.name)
        end
      end
    end
  end
end
