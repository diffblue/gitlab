# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores' do
    describe 'Group with members', product_group: :tenant_scale do
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
        Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)
      end

      before do
        source_group_with_members.add_member(maintainer_user, Resource::Members::AccessLevel::MAINTAINER)
      end

      after do
        project.remove_via_api!
        source_group_with_members.remove_via_api!
        target_group_with_project.remove_via_api!
      end

      it 'can be shared with another group with correct access level',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347935' do
        Flow::Login.sign_in

        target_group_with_project.visit!

        Page::Group::Menu.perform(&:click_subgroup_members_item)
        Page::Group::Members.perform do |members|
          members.invite_group(source_group_with_members.path)

          expect(members).to have_group(source_group_with_members.path)
        end

        Page::Main::Menu.perform(&:sign_out)
        Flow::Login.sign_in(as: maintainer_user)

        Page::Dashboard::Projects.perform do |projects|
          projects.filter_by_name(project.name)

          expect(projects).to have_project_with_access_role(project.name, "Guest")
        end
      end
    end
  end
end
