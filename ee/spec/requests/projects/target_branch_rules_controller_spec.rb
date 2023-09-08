# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TargetBranchRulesController, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.first_owner }

  before do
    login_as(user)
  end

  describe 'POST #create' do
    let(:params) { { name: 'dev/*', target_branch: 'develop' } }

    describe 'when the target_branch_rules_flag flag is disabled' do
      before do
        stub_feature_flags(target_branch_rules_flag: false)
      end

      it 'returns 404' do
        post project_target_branch_rules_path(project), params: { projects_target_branch_rule: params }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'when the project does not have the correct license' do
      before do
        stub_licensed_features(target_branch_rules: false)
      end

      it 'returns 404' do
        post project_target_branch_rules_path(project), params: { projects_target_branch_rule: params }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'with incorrect params' do
      let(:params) { { name: '', target_branch: 'develop' } }

      before do
        stub_licensed_features(target_branch_rules: true)
      end

      it 'redirects with alert message' do
        post project_target_branch_rules_path(project), params: { projects_target_branch_rule: params }

        expect(response).to redirect_to(project_settings_merge_requests_path(project, anchor: 'target-branch-rules'))
        expect(flash[:alert]).to eq("Name can't be blank, Name is invalid")
      end
    end

    describe 'with correct params' do
      before do
        stub_licensed_features(target_branch_rules: true)
      end

      it 'redirects with notice message' do
        post project_target_branch_rules_path(project), params: { projects_target_branch_rule: params }

        expect(response).to redirect_to(project_settings_merge_requests_path(project, anchor: 'target-branch-rules'))
        expect(flash[:notice]).to eq("Target branch rule created.")
      end
    end
  end
end
