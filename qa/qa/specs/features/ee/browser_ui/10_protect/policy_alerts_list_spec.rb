# frozen_string_literal: true

module QA
  RSpec.describe 'Protect' do
    describe 'Threat Monitoring Policy Alert List page' do
      let!(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = Runtime::Env.auto_devops_project_name || 'project-with-protect'
          project.description = 'Project with Protect'
          project.auto_devops_enabled = true
          project.initialize_with_readme = true
          project.template_name = 'express'
        end
      end

      after do
        project.remove_via_api!
      end

      context 'without k8s cluster' do
        before do
          Flow::Login.sign_in
          project.visit!
        end

        it 'can load Threat Monitoring page and view the policy alert list', :smoke, testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/2289' do
          Page::Project::Menu.perform(&:click_on_threat_monitoring)

          EE::Page::Project::ThreatMonitoring::AlertsList.perform do |alerts_list|
            aggregate_failures do
              expect(alerts_list).to have_alerts_tab
              expect(alerts_list).to have_alerts_list
            end
          end
        end
      end
    end
  end
end
