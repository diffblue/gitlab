# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectApprovalRules, :aggregate_failures, feature_category: :source_code_management do
  let_it_be(:group) { create(:group_with_members) }
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:admin) { create(:user, :admin) }
  let_it_be(:project) { create(:project, :public, :repository, creator: user, namespace: user.namespace, only_allow_merge_if_pipeline_succeeds: false) }
  let_it_be(:approver) { create(:user) }
  let_it_be(:other_approver) { create(:user) }

  before do
    stub_licensed_features(admin_merge_request_approvers_rules: true)
  end

  describe 'GET /projects/:id/approval_rules/:approval_rule_id' do
    let_it_be(:private_project) { create(:project, :private, creator: user, namespace: user.namespace) }

    let!(:approval_rule) { create(:approval_project_rule, project: private_project) }
    let(:url) { "/projects/#{private_project.id}/approval_rules/#{approval_rule.id}" }

    context 'when the request is correct' do
      it 'matches the response schema' do
        get api(url, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/project_approval_rule', dir: 'ee')

        rule = json_response

        expect(rule['approvals_required']).to eq(approval_rule.approvals_required)
        expect(rule['id']).to eq(approval_rule.id)
        expect(rule['name']).to eq(approval_rule.name)
      end
    end

    context 'when the user is not authorized' do
      it 'does not display rule information' do
        get api(url, user2)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when license is missing' do
      before do
        stub_licensed_features(admin_merge_request_approvers_rules: false)
      end

      it 'returns 403 error' do
        get api(url, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'GET /projects/:id/approval_rules' do
    let(:url) { "/projects/#{project.id}/approval_rules" }

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
        expect(response).to include_pagination_headers
        expect(response).to match_response_schema('public_api/v4/project_approval_rules', dir: 'ee')

        json = json_response

        expect(json.size).to eq(1)

        rule = json.first

        expect(rule['approvals_required']).to eq(7)
        expect(rule['name']).to eq('vulnerability')
      end

      context 'private group filtering' do
        let_it_be(:private_group) { create :group, :private }

        before do
          rule.groups << private_group
        end

        it 'excludes private groups if user has no access' do
          get api(url, developer)

          json = json_response
          rule = json.first

          expect(rule['groups'].size).to eq(0)
        end

        it 'includes private groups if user has access' do
          private_group.add_owner(developer)

          get api(url, developer)

          json = json_response
          rule = json.first

          expect(rule['groups'].size).to eq(1)
        end
      end

      context 'report_approver rules' do
        let!(:report_approver_rule) do
          create(:approval_project_rule, :license_scanning, project: project)
        end

        it 'includes report_approver rules' do
          get api(url, developer)

          json = json_response

          expect(json.size).to eq(2)
          expect(json.map { |rule| rule['name'] }).to contain_exactly(rule.name, report_approver_rule.name)
        end
      end
    end

    context 'when project is archived' do
      let_it_be(:archived_project) { create(:project, :archived, creator: user) }

      let(:url) { "/projects/#{archived_project.id}/approval_rules" }

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

    context 'when license is missing' do
      before do
        stub_licensed_features(admin_merge_request_approvers_rules: false)
      end

      it 'returns 403 error' do
        get api(url, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'POST /projects/:id/approval_rules' do
    let(:schema) { 'public_api/v4/project_approval_rule' }
    let(:url) { "/projects/#{project.id}/approval_rules" }

    it_behaves_like 'an API endpoint for creating project approval rule'
  end

  describe 'PUT /projects/:id/approval_rules/:approval_rule_id' do
    let!(:approval_rule) { create(:approval_project_rule, project: project) }
    let(:schema) { 'public_api/v4/project_approval_rule' }
    let(:url) { "/projects/#{project.id}/approval_rules/#{approval_rule.id}" }

    it_behaves_like 'an API endpoint for updating project approval rule'
  end

  describe 'DELETE /projects/:id/approval_rules/:approval_rule_id' do
    let!(:approval_rule) { create(:approval_project_rule, project: project) }
    let(:url) { "/projects/#{project.id}/approval_rules/#{approval_rule.id}" }

    it_behaves_like 'an API endpoint for deleting project approval rule'
  end
end
