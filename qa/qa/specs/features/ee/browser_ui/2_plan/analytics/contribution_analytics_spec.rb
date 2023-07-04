# frozen_string_literal: true

module QA
  RSpec.describe 'Plan' do
    describe 'Contribution Analytics', product_group: :optimize do
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

      it(
        'tests contributions',
        :aggregate_failures,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347765'
      ) do
        EE::Page::Group::ContributionAnalytics.perform do |analytics_page|
          expect { analytics_page.push_analytics_content }.to eventually_have_content('3 pushes')
                                                 .within(max_duration: 120, reload_page: analytics_page)
          expect { analytics_page.push_analytics_content }.to eventually_have_content('1 contributor')
                                                 .within(max_duration: 120, reload_page: analytics_page)
          expect { analytics_page.mr_analytics_content }.to eventually_have_content('1 created, 1 merged, 0 closed.')
                                                 .within(max_duration: 120, reload_page: analytics_page)
          expect { analytics_page.issue_analytics_content }.to eventually_have_content('1 created, 1 closed.')
                                                 .within(max_duration: 120, reload_page: analytics_page)
        end
      end
    end
  end
end
