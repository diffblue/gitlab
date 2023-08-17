# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectApprovalSettings, :aggregate_failures, feature_category: :source_code_management do
  let_it_be(:group) { create(:group_with_members) }
  let_it_be(:group2) { create(:group_with_members) }
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:admin) { create(:user, :admin) }
  let_it_be(:project) { create(:project, :public, :repository, creator: user, namespace: user.namespace, only_allow_merge_if_pipeline_succeeds: false) }
  let_it_be(:approver) { create(:user) }
  let_it_be(:other_approver) { create(:user) }

  before do
    stub_licensed_features(merge_request_approvers: true)
  end

  describe 'GET /projects/:id/approval_settings' do
    let(:url) { "/projects/#{project.id}/approval_settings" }

    context 'when the request is correct' do
      let!(:rule) do
        rule = create(:approval_project_rule, name: 'vulnerability', project: project, approvals_required: 7)
        rule.users << approver
        rule
      end

      let(:developer) do
        user = create(:user)
        project.add_guest(user)
        user
      end

      it 'matches the response schema' do
        get api(url, developer)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/project_approval_settings', dir: 'ee')

        json = json_response

        expect(json['rules'].size).to eq(1)

        rule = json['rules'].first

        expect(rule['approvals_required']).to eq(7)
        expect(rule['name']).to eq('vulnerability')
      end

      context 'when license is missing' do
        before do
          stub_licensed_features(merge_request_approvers: false)
        end

        it 'returns 403 error' do
          get api(url, developer)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when target_branch is specified' do
        let(:protected_branch) { create(:protected_branch, project: project, name: 'master') }
        let(:another_protected_branch) { create(:protected_branch, project: project, name: 'test') }

        let!(:another_rule) do
          create(
            :approval_project_rule,
            name: 'test',
            project: project,
            protected_branches: [another_protected_branch]
          )
        end

        before do
          stub_licensed_features(merge_request_approvers: true, multiple_approval_rules: true)
          rule.update!(protected_branches: [protected_branch])
        end

        it 'filters the rules returned by target branch' do
          get api("#{url}?target_branch=test", developer)

          expect(json_response['rules'].size).to eq(1)

          rule_response = json_response['rules'].first

          expect(rule_response['id']).to eq(another_rule.id)
          expect(rule_response['name']).to eq('test')
        end
      end

      context 'private group filtering' do
        let_it_be(:private_group) { create :group, :private }

        before do
          rule.groups << private_group
        end

        it 'excludes private groups if user has no access' do
          get api(url, developer)

          json = json_response
          rule = json['rules'].first

          expect(rule['groups'].size).to eq(0)
        end

        it 'includes private groups if user has access' do
          private_group.add_owner(developer)

          get api(url, developer)

          json = json_response
          rule = json['rules'].first

          expect(rule['groups'].size).to eq(1)
        end
      end

      context 'report_approver rules' do
        let!(:report_approver_rule) do
          create(:approval_project_rule, :code_coverage, project: project)
        end

        it 'includes report_approver rules' do
          get api(url, developer)

          json = json_response

          expect(json['rules'].size).to eq(2)
          expect(json['rules'].map { |rule| rule['name'] }).to contain_exactly(rule.name, report_approver_rule.name)
        end
      end
    end

    context 'when project is archived' do
      let_it_be(:archived_project) { create(:project, :archived, creator: user) }

      let(:url) { "/projects/#{archived_project.id}/approval_settings" }

      context 'when user has normal permissions' do
        it 'returns 403' do
          archived_project.add_guest(user2)

          get api(url, user2)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when user has project admin permissions' do
        it 'allows access' do
          archived_project.add_maintainer(user2)

          get api(url, user2)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe 'POST /projects/:id/approval_settings/rules' do
    let(:schema) { 'public_api/v4/project_approval_setting' }
    let(:url) { "/projects/#{project.id}/approval_settings/rules" }

    it_behaves_like 'an API endpoint for creating project approval rule'
  end

  describe 'PUT /projects/:id/approval_settings/:approval_rule_id' do
    let!(:approval_rule) { create(:approval_project_rule, project: project) }
    let(:schema) { 'public_api/v4/project_approval_setting' }
    let(:url) { "/projects/#{project.id}/approval_settings/rules/#{approval_rule.id}" }

    it_behaves_like 'an API endpoint for updating project approval rule'
  end

  describe 'DELETE /projects/:id/approval_settings/rules/:approval_rule_id' do
    let!(:approval_rule) { create(:approval_project_rule, project: project) }
    let(:url) { "/projects/#{project.id}/approval_settings/rules/#{approval_rule.id}" }

    it_behaves_like 'an API endpoint for deleting project approval rule'
  end
end
