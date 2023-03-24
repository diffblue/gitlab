# frozen_string_literal: true

module QA
  RSpec.describe(
    'Govern',
    product_group: :security_policies) do
    describe 'Policies List page' do
      let!(:project) do
        Resource::Project.fabricate_via_api_unless_fips! do |project|
          project.name = Runtime::Env.auto_devops_project_name || 'project-with-protect'
          project.description = 'Project with Protect'
          project.auto_devops_enabled = true
          project.initialize_with_readme = true
          project.template_name = 'express'
        end
      end

      after do
        if Runtime::Env.personal_access_tokens_disabled?
          project.visit!
          project.remove_via_browser_ui!
        else
          project.remove_via_api!
        end
      end

      before do
        Flow::Login.sign_in
        project.visit!
      end

      it 'can load Policies page and view the policies list', :smoke,
testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347589' do
        Page::Project::Menu.perform(&:go_to_policies)

        EE::Page::Project::Policies::Index.perform do |policies_page|
          aggregate_failures do
            expect(policies_page).to have_policies_list
          end
        end
      end

      it 'can navigate to Policy Editor page', :smoke,
testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347611' do
        Page::Project::Menu.perform(&:go_to_policies)

        EE::Page::Project::Policies::Index.perform(&:click_new_policy_button)

        EE::Page::Project::Policies::PolicyEditor.perform do |policy_editor|
          aggregate_failures do
            expect(policy_editor).to have_policy_selection(:policy_selection_wizard)
          end
        end
      end
    end
  end
end
