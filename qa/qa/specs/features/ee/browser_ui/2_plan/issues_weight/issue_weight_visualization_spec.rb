# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable, product_group: :project_management do
    describe 'Issues weight visualization' do
      before do
        Flow::Login.sign_in
      end

      let(:milestone) { create(:project_milestone) }
      let(:weight) { 1000 }
      let(:issue) { create(:issue, milestone: milestone, project: milestone.project, weight: weight) }

      it 'shows the set weight in the issue page, in the milestone page, and in the issues list page', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347986' do
        issue.visit!

        Page::Project::Issue::Show.perform do |show|
          expect(show.weight_label_value).to have_content(weight)

          show.click_milestone_link
        end

        Page::Milestone::Show.perform do |show|
          expect(show.total_issue_weight_value).to have_content(weight)
        end

        Page::Project::Menu.perform(&:go_to_issues)

        Page::Project::Issue::Index.perform do |index|
          expect(index.issuable_weight).to have_content(weight)
        end
      end
    end
  end
end
