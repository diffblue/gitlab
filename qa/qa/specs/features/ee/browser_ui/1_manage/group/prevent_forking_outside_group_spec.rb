# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'prevent forking outside group', quarantine: {
      only: { subdomain: %i[staging] },
      issue: "https://gitlab.com/gitlab-org/gitlab/-/issues/350854",
      type: :broken
    } do
      let!(:group_for_fork) do
        Resource::Sandbox.fabricate! do |sandbox_group|
          sandbox_group.path = "group_for_fork_#{SecureRandom.hex(8)}"
        end
      end

      let(:project) do
        Resource::Project.fabricate! do |project|
          project.name = "project_to_fork"
          project.initialize_with_readme = true
        end
      end

      context 'when disabled' do
        before do
          set_prevent_forking_outside_group('disabled')
        end

        it 'allows forking outside of group', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347870' do
          project.visit!

          Page::Project::Show.perform(&:fork_project)

          all_namespaces_for_fork = Page::Project::Fork::New.perform(&:fork_namespace_dropdown_values)

          expect(all_namespaces_for_fork).to include(group_for_fork.path)
        end
      end

      context 'when enabled' do
        before do
          set_prevent_forking_outside_group('enabled')
        end

        it 'does not allow forking outside of group', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347872' do
          project.visit!

          Page::Project::Show.perform(&:fork_project)

          all_namespaces_for_fork = Page::Project::Fork::New.perform(&:fork_namespace_dropdown_values)

          expect(all_namespaces_for_fork).not_to include(group_for_fork.path)
        end
      end

      after do
        project.group.sandbox.update_group_setting(group_setting: 'prevent_forking_outside_group', value: false)
        project.remove_via_api!
        group_for_fork.remove_via_api!
      end

      def set_prevent_forking_outside_group(enabled_or_disabled)
        Flow::Login.sign_in
        project.group.sandbox.visit!
        Page::Group::Menu.perform(&:click_group_general_settings_item)
        Page::Group::Settings::General.perform do |general_setting|
          general_setting.send("set_prevent_forking_outside_group_#{enabled_or_disabled}")
        end
      end
    end
  end
end
