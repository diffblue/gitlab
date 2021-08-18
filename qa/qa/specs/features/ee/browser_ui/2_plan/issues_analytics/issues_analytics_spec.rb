# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable do
    shared_examples 'issues analytics page' do
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

    describe 'Group level issues analytics', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1204' do
      it_behaves_like 'issues analytics page' do
        let(:analytics_path) { "#{issue.project.group.web_url}/-/issues_analytics" }
      end
    end

    describe 'Project level issues analytics', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1205' do
      it_behaves_like 'issues analytics page' do
        let(:analytics_path) { "#{issue.project.web_url}/-/analytics/issues_analytics" }
      end
    end
  end
end
