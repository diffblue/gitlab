# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable, product_group: :project_management do
    describe 'Issues weight visualization' do
      before do
        Flow::Login.sign_in
      end

      let(:milestone) do
        Resource::ProjectMilestone.fabricate_via_api!
      end

      let(:weight) { 1000 }

      let(:issue) do
        Resource::Issue.fabricate_via_api! do |issue|
          issue.milestone = milestone
          issue.project = milestone.project
          issue.title = 'keep-the-ring-safe'
          issue.weight = weight
        end
      end

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
