# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TargetBranchRulesController, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.first_owner }

  before do
    login_as(user)
  end

  describe 'GET #index' do
    describe 'when the target_branch_rules_flag flag is disabled' do
      before do
        stub_feature_flags(target_branch_rules_flag: false)
      end

      it 'returns 404' do
        get project_target_branch_rules_path(project)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'when the project does not have the correct license' do
      before do
        stub_licensed_features(target_branch_rules: false)
      end

      it 'returns 404' do
        get project_target_branch_rules_path(project)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'when target_branch_rules_flag is enabled and project has the correct license' do
      before do
        stub_licensed_features(target_branch_rules: true)
        create(:target_branch_rule, project: project, name: 'feature', target_branch: 'other-branch')
      end

      it 'calls TargetBranchRules::FindService' do
        expect_next_instance_of(TargetBranchRules::FindService) do |service|
          expect(service).to receive(:execute).with('feature')
        end

        get project_target_branch_rules_path(project), params: { branch_name: 'feature' }
      end

      it 'renders JSON with target_branch property' do
        get project_target_branch_rules_path(project), params: { branch_name: 'feature' }

        expect(json_response).to include("target_branch" => 'other-branch')
      end
    end
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

  describe 'POST #destroy' do
    let(:params) { { name: 'dev/*', target_branch: 'develop' } }

    describe 'when the target_branch_rules_flag flag is disabled' do
      before do
        stub_feature_flags(target_branch_rules_flag: false)
      end

      it 'returns 404' do
        delete project_target_branch_rule_path(project, non_existing_record_id)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'when the project does not have the correct license' do
      before do
        stub_licensed_features(target_branch_rules: false)
      end

      it 'returns 404' do
        delete project_target_branch_rule_path(project, non_existing_record_id)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'with none existent rule' do
      let(:params) { { id: non_existing_record_id } }

      before do
        stub_licensed_features(target_branch_rules: true)
      end

      it 'redirects with alert message' do
        delete project_target_branch_rule_path(project, non_existing_record_id)

        expect(response).to redirect_to(project_settings_merge_requests_path(project, anchor: 'target-branch-rules'))
        expect(flash[:alert]).to eq("Target branch rule does not exist")
      end
    end

    describe 'with existing rule' do
      let_it_be(:rule) { create(:target_branch_rule, project: project, name: 'feature', target_branch: 'other-branch') }

      before do
        stub_licensed_features(target_branch_rules: true)
      end

      it 'redirects with notice message' do
        delete project_target_branch_rule_path(project, rule)

        expect(response).to redirect_to(project_settings_merge_requests_path(project, anchor: 'target-branch-rules'))
        expect(flash[:notice]).to eq("Target branch rule deleted.")
      end
    end
  end
end
