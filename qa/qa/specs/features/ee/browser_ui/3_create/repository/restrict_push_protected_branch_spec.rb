# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Restricted protected branch push and merge', product_group: :source_code do
      let(:user_developer) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1) }
      let(:user_maintainer) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_2, Runtime::Env.gitlab_qa_password_2) }
      let(:branch_name) { 'protected-branch' }
      let(:commit_message) { 'Protected push commit message' }

      shared_examples 'unselected maintainer' do |testcase|
        it 'user fails to push', testcase: testcase do
          expect { push_new_file(branch_name, as_user: user_maintainer) }.to raise_error(
            QA::Support::Run::CommandError,
            /You are not allowed to push code to protected branches on this project\.([\s\S]+)\[remote rejected\] #{branch_name} -> #{branch_name} \(pre-receive hook declined\)/)
        end
      end

      shared_examples 'selected developer' do |testcase|
        it 'user pushes and merges', testcase: testcase do
          push = push_new_file(branch_name, as_user: user_developer)

          expect(push.output).to match(/To create a merge request for protected-branch, visit/)

          Resource::MergeRequest.fabricate_via_api! do |merge_request|
            merge_request.project = project
            merge_request.target_new_branch = false
            merge_request.source_branch = branch_name
            merge_request.no_preparation = true
          end.visit!

          Page::MergeRequest::Show.perform do |mr|
            mr.merge!

            expect(mr).to have_content(/The changes were merged|Changes merged into/)
          end
        end
      end

      context 'when only one user is allowed to merge and push to a protected branch' do
        let(:project) do
          Resource::Project.fabricate_via_api! do |resource|
            resource.name = 'user-with-access-to-protected-branch'
            resource.initialize_with_readme = true
          end
        end

        before do
          project.add_member(user_developer, Resource::Members::AccessLevel::DEVELOPER)
          project.add_member(user_maintainer, Resource::Members::AccessLevel::MAINTAINER)

          login

          Resource::ProtectedBranch.fabricate_via_browser_ui! do |protected_branch|
            protected_branch.branch_name = branch_name
            protected_branch.project = project
            protected_branch.allowed_to_merge = {
              users: [user_developer]
            }
            protected_branch.allowed_to_push = {
              users: [user_developer]
            }
          end
        end

        after do
          project.remove_via_api!
        end

        it_behaves_like 'unselected maintainer', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347775'
        it_behaves_like 'selected developer', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347774'
      end

      context 'when only one group is allowed to merge and push to a protected branch' do
        let(:group) do
          Resource::Group.fabricate_via_api! do |group|
            group.path = "access-to-protected-branch-#{SecureRandom.hex(8)}"
          end
        end

        let(:project) do
          Resource::Project.fabricate_via_api! do |resource|
            resource.name = 'group-with-access-to-protected-branch'
            resource.initialize_with_readme = true
          end
        end

        before do
          login

          group.add_member(user_developer, Resource::Members::AccessLevel::DEVELOPER)
          project.invite_group(group, Resource::Members::AccessLevel::DEVELOPER)

          project.add_member(user_maintainer, Resource::Members::AccessLevel::MAINTAINER)

          Resource::ProtectedBranch.fabricate_via_browser_ui! do |protected_branch|
            protected_branch.branch_name = branch_name
            protected_branch.project = project
            protected_branch.allowed_to_merge = {
              groups: [group]
            }
            protected_branch.allowed_to_push = {
              groups: [group]
            }
          end
        end

        after do
          project.remove_via_api!
          group.remove_via_api!
        end

        it_behaves_like 'unselected maintainer', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347772'
        it_behaves_like 'selected developer', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347773'
      end

      def login(as_user: Runtime::User)
        Page::Main::Menu.perform(&:sign_out_if_signed_in)

        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform do |login|
          login.sign_in_using_credentials(user: as_user)
        end
      end

      def push_new_file(branch_name, as_user: user)
        Resource::Repository::Push.fabricate! do |push|
          push.repository_http_uri = project.repository_http_location.uri
          push.branch_name = branch_name
          push.new_branch = false
          push.user = as_user
        end
      end
    end
  end
end
