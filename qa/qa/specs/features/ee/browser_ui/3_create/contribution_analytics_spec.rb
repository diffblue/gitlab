# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Contribution Analytics' do
      let(:group) do
        Resource::Group.fabricate_via_api! do |group|
          group.path = "contribution_analytics-#{SecureRandom.hex(8)}"
        end
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'contribution_analytics'
          project.group = group
        end
      end

      let(:issue) do
        Resource::Issue.fabricate_via_api! do |issue|
          issue.project = project
        end
      end

      let(:mr) do
        Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.project = project
        end
      end

      before do
        Flow::Login.sign_in

        issue.visit!
        Page::Project::Issue::Show.perform(&:click_close_issue_button)

        mr.visit!
        Page::MergeRequest::Show.perform(&:merge!)

        group.visit!
        Page::Group::Menu.perform(&:click_contribution_analytics_item)
      end

      it 'tests contributions', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1864' do
        EE::Page::Group::ContributionAnalytics.perform do |contribution_analytics|
          expect(contribution_analytics).to have_push_element('3 pushes, more than 4 commits by 1 person contributors.')
          expect(contribution_analytics).to have_mr_element('1 created, 1 merged, 0 closed.')
          expect(contribution_analytics).to have_issue_element('1 created, 1 closed.')
        end
      end
    end
  end
end
