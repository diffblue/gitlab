# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IssuesController do
  let_it_be(:issue) { create(:issue) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { issue.project }
  let_it_be(:user) { issue.author }
  let_it_be(:blocking_issue) { create(:issue, project: project) }
  let_it_be(:blocked_by_issue) { create(:issue, project: project) }

  before do
    login_as(user)
  end

  describe 'GET #show' do
    def get_show
      get project_issue_path(project, issue)
    end

    context 'with blocking issues' do
      before do
        get_show # Warm the cache
      end

      it 'does not cause extra queries when multiple blocking issues are present' do
        create(:issue_link, source: blocking_issue, target: issue, link_type: IssueLink::TYPE_BLOCKS)

        control = ActiveRecord::QueryRecorder.new { get_show }

        other_project_issue = create(:issue)
        other_project_issue.project.add_developer(user)
        create(:issue_link, source: other_project_issue, target: issue, link_type: IssueLink::TYPE_BLOCKS)

        expect { get_show }.not_to exceed_query_limit(control)
      end
    end

    context 'with test case' do
      before do
        project.add_guest(user)
      end

      it 'redirects to test cases show' do
        test_case = create(:quality_test_case, project: project)

        get project_issue_path(project, test_case)

        expect(response).to redirect_to(project_quality_test_case_path(project, test_case))
      end
    end

    it 'exposes the escalation_policies licensed feature setting' do
      stub_licensed_features(escalation_policies: true)

      get_show

      expect(response.body).to have_pushed_frontend_feature_flags(escalationPolicies: true)
    end
  end

  describe 'GET #index' do
    def get_issues
      get project_issues_path(project, params: params)
    end

    context 'when listing epic issues' do
      let_it_be(:epic) { create(:epic, group: group) }
      let_it_be(:subepic) { create(:epic, group: group, parent: epic) }

      let(:params) { { epic_id: epic.id, include_subepics: true } }

      before do
        get_issues # Warm the cache
      end

      it 'does not cause extra queries when there are other subepic issues' do
        create(:epic_issue, issue: issue, epic: epic)

        control = ActiveRecord::QueryRecorder.new { get_issues }

        subepic_issue = create(:issue, project: project)
        create(:epic_issue, issue: subepic_issue, epic: subepic)

        expect { get_issues }.not_to exceed_query_limit(control)
      end
    end
  end
end
