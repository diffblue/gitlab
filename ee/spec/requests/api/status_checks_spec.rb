# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::StatusChecks do
  include AccessMatchersForRequest
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:rule) { create(:external_status_check, project: project) }
  let_it_be(:rule_2) { create(:external_status_check, project: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:project_maintainer) { create(:user) }

  let(:single_object_url) { "/projects/#{project.id}/external_status_checks/#{rule.id}" }
  let(:collection_url) { "/projects/#{project.id}/external_status_checks" }
  let(:sha) { merge_request.source_branch_sha }
  let(:user) { project_maintainer }

  subject { post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/status_check_responses", user), params: { external_status_check_id: rule.id, sha: sha } }

  describe 'permissions' do
    before do
      stub_licensed_features(external_status_checks: true)
    end

    it { expect { subject }.to be_allowed_for(:maintainer).of(project) }
    it { expect { subject }.to be_allowed_for(:developer).of(project) }
    it { expect { subject }.to be_denied_for(:reporter).of(project) }
  end

  describe 'GET :id/merge_requests/:merge_request_iid/status_checks' do
    subject { get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/status_checks", user), params: { external_status_check_id: rule.id, sha: sha } }

    context 'when current_user has access' do
      before do
        stub_licensed_features(external_status_checks: true)
        project.add_user(project_maintainer, :maintainer)
      end

      context 'when merge request has received status check responses' do
        let!(:non_applicable_check) { create(:external_status_check, project: project, protected_branches: [create(:protected_branch, name: 'different-branch', project: project)]) }
        let!(:branch_specific_check) { create(:external_status_check, project: project, protected_branches: [create(:protected_branch, name: merge_request.target_branch, project: project)]) }
        let!(:status_check_response) { create(:status_check_response, external_status_check: rule, merge_request: merge_request, sha: sha) }

        it 'returns a 200' do
          subject

          expect(response).to have_gitlab_http_status(:success)
        end

        it 'returns the total number of status checks for the MRs project' do
          subject

          expect(json_response.size).to eq(3)
        end

        it 'has the correct status values' do
          subject

          expect(json_response[0]["status"]).to eq('approved')
          expect(json_response[1]["status"]).to eq('pending')
          expect(json_response[2]["status"]).to eq('pending')
        end
      end
    end
  end

  describe 'POST :id/:merge_requests/:merge_request_iid/status_check_responses' do
    subject { post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/status_check_responses", user), params: { external_status_check_id: rule.id, sha: sha } }

    context 'when user has access' do
      before do
        stub_licensed_features(external_status_checks: true)
        project.add_user(project_maintainer, :maintainer)
      end

      it 'returns a 201' do
        subject

        expect(response).to have_gitlab_http_status(:created)
      end

      it 'returns the status checks as JSON' do
        subject

        expect(json_response.keys).to contain_exactly('id', 'merge_request', 'external_status_check')
      end

      it 'creates new StatusCheckResponse with correct attributes' do
        expect { subject }.to change { MergeRequests::StatusCheckResponse.count }.by 1
      end

      context 'when sha is not the source branch HEAD' do
        let(:sha) { 'notarealsha' }

        it 'does not create a new approval' do
          expect { subject }.not_to change { MergeRequests::StatusCheckResponse.count }
        end

        it 'returns a conflict error' do
          subject

          expect(response).to have_gitlab_http_status(:conflict)
        end
      end

      context 'when user is not authenticated' do
        let(:user) { nil }

        it 'returns an unauthorized status' do
          subject

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end
  end

  describe 'DELETE projects/:id/external_status_checks/:check_id' do
    before do
      stub_licensed_features(external_status_checks: true)
    end

    it 'deletes the specified rule' do
      expect do
        delete api(single_object_url, project.owner)
      end.to change { MergeRequests::ExternalStatusCheck.count }.by(-1)
    end

    context 'when feature is disabled, unlicensed or user has permission' do
      where(:licensed, :project_owner, :status) do
        false | false | :not_found
        false | true  | :unauthorized
        true  | false | :not_found
        true  | true  | :success
      end

      with_them do
        before do
          stub_licensed_features(external_status_checks: licensed)
        end

        it 'returns the correct status code' do
          delete api(single_object_url, (project_owner ? project.owner : build(:user)))

          expect(response).to have_gitlab_http_status(status)
        end
      end
    end
  end

  describe 'POST projects/:id/external_status_checks' do
    context 'successfully creating new external approval rule' do
      before do
        stub_licensed_features(external_status_checks: true)
      end

      subject do
        post api("/projects/#{project.id}/external_status_checks", project.owner), params: attributes_for(:external_status_check)
      end

      it 'creates a new external approval rule' do
        expect { subject }.to change { MergeRequests::ExternalStatusCheck.count }.by(1)
      end

      context 'with protected branches' do
        let_it_be(:protected_branch) { create(:protected_branch, project: project) }

        let(:params) do
          { name: 'New rule', external_url: 'https://gitlab.com/test/example.json', protected_branch_ids: protected_branch.id }
        end

        subject do
          post api("/projects/#{project.id}/external_status_checks", project.owner), params: params
        end

        it 'returns expected status code' do
          subject

          expect(response).to have_gitlab_http_status(:created)
        end

        it 'creates protected branch records' do
          subject

          expect(MergeRequests::ExternalStatusCheck.last.protected_branches.count).to eq 1
        end

        it 'responds with expected JSON' do
          subject

          expect(json_response['id']).not_to be_nil
          expect(json_response['name']).to eq('New rule')
          expect(json_response['external_url']).to eq('https://gitlab.com/test/example.json')
          expect(json_response['protected_branches'].size).to eq(1)
        end
      end
    end

    context 'when feature is disabled, unlicensed or user has permission' do
      where(:licensed, :project_owner, :status) do
        false | false | :not_found
        false | true  | :unauthorized
        true  | false | :not_found
        true  | true  | :created
      end

      with_them do
        before do
          stub_licensed_features(external_status_checks: licensed)
        end

        it 'returns the correct status code' do
          post api("/projects/#{project.id}/external_status_checks", (project_owner ? project.owner : build(:user))), params: attributes_for(:external_status_check)

          expect(response).to have_gitlab_http_status(status)
        end
      end
    end
  end

  describe 'GET projects/:id/external_status_checks' do
    let_it_be(:protected_branches) { create_list(:protected_branch, 3, project: project) }

    before_all do
      create(:external_status_check) # Creating an orphaned rule to make sure project scoping works as expected
    end

    before do
      stub_licensed_features(external_status_checks: true)
    end

    it 'responds with expected JSON', :aggregate_failures do
      get api(collection_url, project.owner)

      expect(json_response.size).to eq(2)
      expect(json_response.map { |r| r['name'] }).to contain_exactly('rule 1', 'rule 2')
    end

    it 'paginates correctly' do
      get api(collection_url, project.owner), params: { per_page: 1 }

      expect_paginated_array_response([rule.id])
    end

    context 'when feature is disabled, unlicensed or user has permission' do
      where(:licensed, :project_owner, :status) do
        false | false | :not_found
        false | true  | :unauthorized
        true  | false | :not_found
        true  | true  | :success
      end

      with_them do
        before do
          stub_licensed_features(external_status_checks: licensed)
        end

        it 'returns the correct status code' do
          get api(collection_url, (project_owner ? project.owner : build(:user)))

          expect(response).to have_gitlab_http_status(status)
        end
      end
    end
  end

  describe 'PUT projects/:id/external_status_checks/:check_id' do
    let(:params) { { external_url: 'http://newvalue.com', name: 'new name' } }

    context 'successfully updating external approval rule' do
      before do
        stub_licensed_features(external_status_checks: true)
      end

      subject do
        put api(single_object_url, project.owner), params: params
      end

      it 'updates an approval rule' do
        expect { subject }.to change { rule.reload.external_url }.to eq('http://newvalue.com')
      end

      it 'responds with correct http status' do
        subject

        expect(response).to have_gitlab_http_status(:success)
      end

      context 'when referencing a protected branch outside of the project' do
        let_it_be(:protected_branch) { create(:protected_branch) }

        let(:params) do
          { name: 'New rule', external_url: 'https://gitlab.com/test/example.json', protected_branch_ids: protected_branch.id }
        end

        subject do
          put api(single_object_url, project.owner), params: params
        end

        it 'is invalid' do
          subject

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end

      context 'with protected branches' do
        let_it_be(:protected_branch) { create(:protected_branch, project: project) }

        let(:params) do
          { name: 'New rule', external_url: 'https://gitlab.com/test/example.json', protected_branch_ids: protected_branch.id }
        end

        subject do
          put api(single_object_url, project.owner), params: params
        end

        it 'returns expected status code' do
          subject

          expect(response).to have_gitlab_http_status(:success)
        end

        it 'creates protected branch records' do
          expect { subject }.to change { MergeRequests::ExternalStatusCheck.last.protected_branches }
        end

        it 'responds with expected JSON', :aggregate_failures do
          subject

          expect(json_response['id']).not_to be_nil
          expect(json_response['name']).to eq('New rule')
          expect(json_response['external_url']).to eq('https://gitlab.com/test/example.json')
          expect(json_response['protected_branches'].size).to eq(1)
        end
      end
    end

    context 'when feature is disabled, unlicensed or user has permission' do
      where(:licensed, :project_owner, :status) do
        false | false | :not_found
        false | true  | :unauthorized
        true  | false | :not_found
        true  | true  | :success
      end

      with_them do
        before do
          stub_licensed_features(external_status_checks: licensed)
        end

        it 'returns the correct status code' do
          put api(single_object_url, (project_owner ? project.owner : build(:user))), params: attributes_for(:external_status_check)

          expect(response).to have_gitlab_http_status(status)
        end
      end
    end
  end
end
