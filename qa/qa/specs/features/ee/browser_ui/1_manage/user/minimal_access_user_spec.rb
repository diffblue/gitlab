# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'User with minimal access to group', :requires_admin, product_group: :authentication_and_authorization do
      let(:admin_api_client) { Runtime::API::Client.as_admin }

      let(:user_with_minimal_access) do
        Resource::User.fabricate_via_api! do |user|
          user.api_client = admin_api_client
        end
      end

      let(:group) do
        group = Resource::Group.fabricate_via_api! do |group|
          group.api_client = admin_api_client
        end
        group.sandbox.add_member(user_with_minimal_access, Resource::Members::AccessLevel::MINIMAL_ACCESS)
        group
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.group = group
          project.name = "project-for-minimal-access"
          project.api_client = admin_api_client
          project.initialize_with_readme = true
        end
      end

      it 'is not allowed to edit files via the UI', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347869' do
        Flow::Login.sign_in(as: user_with_minimal_access)
        project.visit!

        Page::Project::Show.perform do |project|
          project.click_file('README.md')
        end

        Page::File::Show.perform(&:click_edit)

        expect(page).to have_text("You can’t edit files directly in this project.")
      end

      after do
        user_with_minimal_access&.remove_via_api!
        project&.remove_via_api!
        begin
          group&.remove_via_api!
        rescue Resource::ApiFabricator::ResourceNotDeletedError
          # It is ok if the group is already marked for deletion by another test
        end
      end
    end
  end
end
