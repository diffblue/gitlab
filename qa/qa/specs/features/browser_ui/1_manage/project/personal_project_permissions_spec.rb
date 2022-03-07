# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :requires_admin do
    describe 'Personal project permissions' do
      let!(:admin_api_client) { Runtime::API::Client.as_admin }

      let!(:owner) do
        Resource::User.fabricate_via_api! do |user|
          user.api_client = admin_api_client
        end
      end

      let!(:owner_api_client) { Runtime::API::Client.new(:gitlab, user: owner) }

      let!(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.api_client = owner_api_client
          project.name = 'qa-owner-personal-project'
          project.personal_namespace = owner.username
        end
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

        it "has Owner role with Owner permissions", testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/352542' do
          Page::Dashboard::Projects.perform do |projects|
            expect(projects).to have_project_with_access_role(project.name, 'Owner')
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

      context 'when user is added as Maintainer' do
        let(:maintainer) do
          Resource::User.fabricate_via_api! do |user|
            user.api_client = admin_api_client
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

        it "has Maintainer role without Owner permissions", testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/352607' do
          Page::Dashboard::Projects.perform do |projects|
            expect(projects).to have_project_with_access_role(project.name, 'Maintainer')
          end

          issue.visit!

          Page::Project::Issue::Show.perform do |issue|
            expect(issue).not_to have_delete_issue_button
          end
        end
      end
    end
  end
end
