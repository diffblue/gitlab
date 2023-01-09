# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MergeRequestsController, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }
  let(:user) { merge_request.author }

  before do
    login_as(user)
  end

  describe 'GET #show' do
    before do
      stub_licensed_features(sast: true)
    end

    def get_show
      get project_merge_request_path(project, merge_request)
    end

    context 'when the user has developer access' do
      it 'publishes the security_reports_mr_widget_prompt experiment' do
        # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/343375
        # More: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/73034#note_720186839
        #       https://docs.gitlab.com/ee/development/query_count_limits.html#disable-query-limiting
        allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(110)
        expect_next_instance_of(SecurityReportsMrWidgetPromptExperiment) do |instance|
          expect(instance).to receive(:publish)
        end

        get_show
      end
    end

    context 'when the user does not have developer access' do
      let(:user) { create(:user) }

      it 'does not publish the security_reports_mr_widget_prompt experiment' do
        expect(SecurityReportsMrWidgetPromptExperiment).not_to receive(:new)

        get_show
      end
    end

    context 'when the project is not licensed for sast' do
      before do
        stub_licensed_features(sast: false)
      end

      it 'does not publish the security_reports_mr_widget_prompt experiment' do
        expect(SecurityReportsMrWidgetPromptExperiment).not_to receive(:new)

        get_show
      end
    end

    context 'when the project has disabled the security and compliance features' do
      before do
        project.project_feature.update_column(:security_and_compliance_access_level, Featurable::DISABLED)
      end

      it 'does not publish the security_reports_mr_widget_prompt experiment' do
        expect(SecurityReportsMrWidgetPromptExperiment).not_to receive(:new)

        get_show
      end
    end

    context 'when the the user is a guest' do
      let(:user) { create(:user) }

      it 'does not publish the security_reports_mr_widget_prompt experiment' do
        project.add_guest(user)

        expect(SecurityReportsMrWidgetPromptExperiment).not_to receive(:new)

        get_show
      end
    end
  end

  describe 'GET #edit' do
    def get_edit
      get edit_project_merge_request_path(project, merge_request)
    end

    context 'when the project requires code owner approval' do
      before do
        stub_licensed_features(code_owners: true, code_owner_approval_required: true)

        get_edit # Warm the cache
      end

      it 'does not cause an extra queries when code owner rules are present' do
        control = ActiveRecord::QueryRecorder.new { get_edit }

        create(:code_owner_rule, merge_request: merge_request)

        # Threshold of 3 because we load the source_rule, users & group users for all rules
        expect { get_edit }.not_to exceed_query_limit(control).with_threshold(3)
      end

      it 'does not cause extra queries when multiple code owner rules are present' do
        create(:code_owner_rule, merge_request: merge_request)

        control = ActiveRecord::QueryRecorder.new { get_edit }

        create(:code_owner_rule, merge_request: merge_request)

        expect { get_edit }.not_to exceed_query_limit(control)
      end
    end
  end

  describe 'GET #index' do
    def get_index
      get project_merge_requests_path(project, state: 'opened')
    end

    it 'avoids N+1' do
      other_user = create(:user)
      create(:merge_request, :unique_branches, target_project: project, source_project: project)
      create_list(:approval_project_rule, 5, project: project, users: [user, other_user], approvals_required: 2)
      create_list(:approval_merge_request_rule, 5, merge_request: merge_request, users: [user, other_user], approvals_required: 2)

      control_count = ActiveRecord::QueryRecorder.new { get_index }.count

      create_list(:approval, 10)
      create(:approval_project_rule, project: project, users: [user, other_user], approvals_required: 2)
      create_list(:merge_request, 20, :unique_branches, target_project: project, source_project: project).each do |mr|
        create(:approval_merge_request_rule, merge_request: mr, users: [user, other_user], approvals_required: 2)
      end

      expect { get_index }.not_to exceed_query_limit(control_count)
    end
  end
end
