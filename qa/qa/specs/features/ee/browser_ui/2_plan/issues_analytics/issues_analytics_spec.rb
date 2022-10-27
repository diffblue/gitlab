# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable, product_group: :optimize do
    shared_examples 'issues analytics page' do
      let(:gitlab_address) { QA::Runtime::Scenario.gitlab_address }

      let(:issue) do
        Resource::Issue.fabricate_via_api!
      end

      before do
        Flow::Login.sign_in
      end

      it 'displays a graph' do
        page.visit(analytics_path)

        EE::Page::Group::IssuesAnalytics.perform do |issues_analytics|
          expect(issues_analytics.graph).to be_visible
        end
      end
    end

    describe 'Group level issues analytics', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347974' do
      it_behaves_like 'issues analytics page' do
        let(:analytics_path) { "#{gitlab_address}/groups/#{issue.project.group.full_path}/-/issues_analytics" }
      end
    end

    describe 'Project level issues analytics', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347973' do
      it_behaves_like 'issues analytics page' do
        let(:analytics_path) { "#{gitlab_address}/#{issue.project.full_path}/-/analytics/issues_analytics" }
      end
    end
  end
end
