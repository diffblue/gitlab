# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    # TODO: Remove :requires_admin meta when the `Runtime::Feature.enable` method call is removed
    describe 'Group with members', :requires_admin do
      let(:admin_api_client) { Runtime::API::Client.as_admin }

      let(:source_group_with_members) do
        Resource::Group.fabricate_via_api! do |group|
          group.path = "source-group-with-members_#{SecureRandom.hex(8)}"
        end
      end

      let(:target_group_with_project) do
        Resource::Group.fabricate_via_api! do |group|
          group.path = "target-group-with-project_#{SecureRandom.hex(8)}"
        end
      end

      let!(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.group = target_group_with_project
          project.initialize_with_readme = true
        end
      end

      let(:maintainer_user) do
        Resource::User.fabricate_via_api! do |resource|
          resource.api_client = admin_api_client
        end
      end

      before do
        Runtime::Feature.enable(:invite_members_group_modal)

        source_group_with_members.add_member(maintainer_user, Resource::Members::AccessLevel::MAINTAINER)
      end

      it 'can be shared with another group with correct access level', :requires_admin, testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/945' do
        Flow::Login.sign_in

        target_group_with_project.visit!

        Page::Group::Menu.perform(&:click_subgroup_members_item)
        Page::Group::Members.perform do |members|
          members.invite_group(source_group_with_members.path)

          expect(members).to have_existing_group_share(source_group_with_members.path)
        end

        Page::Main::Menu.perform(&:sign_out)
        Flow::Login.sign_in(as: maintainer_user)

        Page::Dashboard::Projects.perform do |projects|
          expect(projects).to have_project_with_access_role(project.name, "Guest")
        end
      end
    end
  end
end
