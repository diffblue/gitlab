# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    shared_examples 'default insights page' do
      it 'displays issues and merge requests dashboards' do
        EE::Page::Insights::Show.perform do |show|
          show.wait_for_insight_charts_to_load

          expect(show).to have_insights_dashboard_title('Issues Dashboard')

          show.select_insights_dashboard('Merge requests dashboard')

          expect(show).to have_insights_dashboard_title('Merge requests dashboard')
        end
      end
    end

    context 'group insights page', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1499' do
      before do
        Flow::Login.sign_in

        Resource::Group.fabricate_via_api!.visit!

        Page::Group::Menu.perform(&:click_group_insights_link)
      end

      it_behaves_like 'default insights page'
    end

    context 'project insights page', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1497' do
      before do
        Flow::Login.sign_in

        project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-insights'
          project.description = 'Project Insights'
        end

        project.visit!

        Page::Project::Menu.perform(&:click_project_insights_link)
      end

      it_behaves_like 'default insights page'
    end
  end
end
