# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable, product_group: :project_management do
    describe 'Burndown chart' do
      include ::QA::Support::Dates

      let(:milestone) do
        Resource::ProjectMilestone.fabricate_via_api! do |m|
          m.start_date = current_date_yyyy_mm_dd
          m.due_date = next_month_yyyy_mm_dd
        end
      end

      before do
        Flow::Login.sign_in

        weight_of_two = 2

        create_issue(milestone.project, milestone, weight_of_two)
        create_issue(milestone.project, milestone, weight_of_two)
      end

      it 'shows burndown chart on milestone page', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347972' do
        milestone.visit!

        Page::Milestone::Show.perform do |show|
          expect(show.burndown_chart).to be_visible
          expect(show.burndown_chart).to have_content("Remaining")

          show.click_weight_button

          expect(show.burndown_chart).to have_content('Remaining')
        end
      end

      def create_issue(project, milestone, weight)
        Resource::Issue.fabricate_via_api! do |issue|
          issue.project = project
          issue.milestone = milestone
          issue.weight = weight
        end
      end
    end
  end
end
