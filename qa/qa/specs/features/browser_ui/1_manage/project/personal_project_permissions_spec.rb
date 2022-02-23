# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :requires_admin do
    describe 'Personal project permissions' do
      before(:context) do
        @admin_api_client = Runtime::API::Client.as_admin
        @feature_flag = :personal_project_owner_with_owner_access
        @feature_flag_state = Runtime::Feature.enabled?(@feature_flag)
      end

      after(:context) do
        Runtime::Feature.set({ @feature_flag => @feature_flag_state }) if @feature_flag_state != Runtime::Feature.enabled?(@feature_flag)
      end

      shared_examples 'has correct role and Owner permissions' do |role, testcase|
        it "has #{role} role with Owner permissions", testcase: testcase do
          Page::Dashboard::Projects.perform do |projects|
            expect(projects).to have_project_with_access_role(project.name, role)
          end

          issue.visit!

          Page::Project::Issue::Show.perform do |issue|
            issue.delete_issue
          end

          Page::Project::Issue::Index.perform do |index|
            expect(index).not_to have_issue(issue)
          end
        end
      end

      shared_examples 'has correct role and no Owner permissions' do |role, testcase|
        it "has #{role} role without Owner permissions", testcase: testcase do
          Page::Dashboard::Projects.perform do |projects|
            expect(projects).to have_project_with_access_role(project.name, role)
          end

          issue.visit!

          Page::Project::Issue::Show.perform do |issue|
            expect(issue).not_to have_delete_issue_button
          end
        end
      end

      context 'with personal_project_owner_with_owner_access feature enabled' do
        let(:owner) do
          Resource::User.fabricate_via_api! do |user|
            user.api_client = @admin_api_client
          end
        end

        let(:owner_api_client) { Runtime::API::Client.new(:gitlab, user: owner) }

        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.api_client = owner_api_client
            project.name = 'qa-owner-as-owner-project'
            project.personal_namespace = owner.username
          end
        end

        before do
          Runtime::Feature.enable(@feature_flag)
          project
        end

        after do
          project&.remove_via_api!
          owner&.remove_via_api!
        end

        context 'when user is added as Owner' do
          let(:issue) do
            Resource::Issue.fabricate_via_api! do |issue|
              issue.api_client = owner_api_client
              issue.project = project
              issue.title = 'Test Owner deletes issue'
            end
          end

          before do
            Flow::Login.sign_in(as: owner)
          end

          it_behaves_like 'has correct role and Owner permissions', 'Owner', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/352542'
        end

        context 'when user is added as Maintainer' do
          let(:maintainer) do
            Resource::User.fabricate_via_api! do |user|
              user.api_client = @admin_api_client
            end
          end

          let(:issue) do
            Resource::Issue.fabricate_via_api! do |issue|
              issue.api_client = owner_api_client
              issue.project = project
              issue.title = 'Test Maintainer deletes issue'
            end
          end

          before do
            project.add_member(maintainer, Resource::Members::AccessLevel::MAINTAINER)
            Flow::Login.sign_in(as: maintainer)
          end

          after do
            maintainer&.remove_via_api!
          end

          it_behaves_like 'has correct role and no Owner permissions', 'Maintainer', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/352607'
        end
      end

      context 'with personal_project_owner_with_owner_access feature disabled' do
        let(:owner) do
          Resource::User.fabricate_via_api! do |user|
            user.api_client = @admin_api_client
          end
        end

        let(:owner_api_client) { Runtime::API::Client.new(:gitlab, user: owner) }

        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.api_client = owner_api_client
            project.name = 'qa-owner-as-maintainer-project'
            project.personal_namespace = owner.username
          end
        end

        before do
          Runtime::Feature.disable(@feature_flag)
          project
        end

        after do
          project&.remove_via_api!
          owner&.remove_via_api!
        end

        context 'when user is added as Owner' do
          let(:issue) do
            Resource::Issue.fabricate_via_api! do |issue|
              issue.api_client = owner_api_client
              issue.project = project
              issue.title = 'Test Owner deletes issue'
            end
          end

          before do
            Flow::Login.sign_in(as: owner)
          end

          it_behaves_like 'has correct role and Owner permissions', 'Maintainer', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/352621'
        end

        context 'when user is added as Maintainer' do
          let(:maintainer) do
            Resource::User.fabricate_via_api! do |user|
              user.api_client = @admin_api_client
            end
          end

          let(:issue) do
            Resource::Issue.fabricate_via_api! do |issue|
              issue.api_client = owner_api_client
              issue.project = project
              issue.title = 'Test Maintainer deletes issue'
            end
          end

          before do
            project.add_member(maintainer, Resource::Members::AccessLevel::MAINTAINER)
            Flow::Login.sign_in(as: maintainer)
          end

          after do
            maintainer&.remove_via_api!
          end

          it_behaves_like 'has correct role and no Owner permissions', 'Maintainer', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/352622'
        end
      end
    end
  end
end
