# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::StatusChecks, feature_category: :compliance_management do
  include AccessMatchersForRequest
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:another_project) { create(:project, :repository, :public) }
  let_it_be(:rule) { create(:external_status_check, project: project, external_url: 'https://mock.api.test/status?token=123456789') }
  let_it_be(:rule_2) { create(:external_status_check, project: project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: user) }

  let(:single_object_url) { "/projects/#{project.id}/external_status_checks/#{rule.id}" }
  let(:collection_url) { "/projects/#{project.id}/external_status_checks" }
  let(:sha) { merge_request.diff_head_sha }
  let(:status) { '' }

  subject { get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/status_checks", user), params: { external_status_check_id: rule.id, sha: sha } }

  describe 'GET :id/merge_requests/:merge_request_iid/status_checks' do
    before do
      stub_licensed_features(external_status_checks: true)
    end

    context 'external url response' do
      context 'when access level is at least `reporter`' do
        before do
          project.add_member(user, :reporter)
        end

        it 'is empty' do
          subject

          expect(json_response[0]["external_url"]).to eq('')
          expect(json_response[1]["external_url"]).to eq('')
        end
      end

      context 'when access level is at least `developer`' do
        before do
          project.add_member(user, :developer)
        end

        it 'has excluded the sensitive token url param' do
          subject

          expect(json_response[0]["external_url"]).to eq('https://mock.api.test/status')
          expect(json_response[1]["external_url"]).to eq(rule_2.external_url)
        end
      end
    end

    context 'when current_user has access' do
      before do
        project.add_member(user, :maintainer)
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

          expect(json_response[0]["status"]).to eq('passed')
          expect(json_response[1]["status"]).to eq('pending')
          expect(json_response[2]["status"]).to eq('pending')
        end
      end
    end
  end

  describe 'POST :id/:merge_requests/:merge_request_iid/status_check_responses' do
    subject { post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/status_check_responses", user), params: { external_status_check_id: rule.id, sha: sha, status: status } }

    let(:status) { 'passed' }

    context 'permissions' do
      using RSpec::Parameterized::TableSyntax

      where(:user_permissions, :applies_to_target_project, :expected_status) do
        :maintainer | true  | :created
        :maintainer | false | :not_found
        :developer  | true  | :created
        :developer  | false | :not_found
        :guest      | true  | :forbidden
        :guest      | false | :not_found
      end

      with_them do
        before do
          stub_licensed_features(external_status_checks: true)

          if applies_to_target_project
            project.add_member(user, user_permissions)
          else
            another_project.add_member(user, user_permissions)
          end
        end

        it 'returns the correct status' do
          subject

          expect(response).to have_gitlab_http_status(expected_status)
        end
      end
    end

    context 'when user has access' do
      before do
        stub_licensed_features(external_status_checks: true)
        project.add_member(user, :maintainer) if user
      end

      context 'when external status check ID does not belong to the requested project' do
        let_it_be(:rule) { create(:external_status_check) }

        it 'returns a not found status' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
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
        delete api(single_object_url, project.first_owner)
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
          delete api(single_object_url, (project_owner ? project.first_owner : build(:user)))

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
        post api("/projects/#{project.id}/external_status_checks", project.first_owner), params: attributes_for(:external_status_check)
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
          post api("/projects/#{project.id}/external_status_checks", project.first_owner), params: params
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
      get api(collection_url, project.first_owner)

      expect(json_response.size).to eq(2)
      expect(json_response.map { |r| r['name'] }).to contain_exactly('rule 1', 'rule 2')
    end

    it 'paginates correctly' do
      get api(collection_url, project.first_owner), params: { per_page: 1 }

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
          get api(collection_url, (project_owner ? project.first_owner : build(:user)))

          expect(response).to have_gitlab_http_status(status)
        end
      end
    end
  end

  describe 'POST :id/merge_requests/:merge_request_iid/status_checks/:external_status_check_id' do
    subject(:retry_failed_status_check) do
      post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/status_checks/#{rule.id}/retry", user)
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(external_status_checks: false)
        project.add_member(user, :maintainer)
      end

      it 'returns unauthorized status' do
        retry_failed_status_check

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when licensed' do
      using RSpec::Parameterized::TableSyntax

      before do
        stub_licensed_features(external_status_checks: true)
      end

      context 'permissions' do
        where(:user_permissions, :applies_to_target_project, :expected_status) do
          :maintainer | true  | :accepted
          :maintainer | false | :not_found
          :developer  | true  | :accepted
          :developer  | false | :not_found
          :guest      | true  | :forbidden
          :guest      | false | :not_found
        end

        with_them do
          before do
            if applies_to_target_project
              project.add_member(user, user_permissions)
            else
              another_project.add_member(user, user_permissions)
            end

            create(:status_check_response, merge_request: merge_request,
                                           external_status_check: rule, sha: merge_request.diff_head_sha, status: 'failed')
          end

          it 'returns the correct status' do
            retry_failed_status_check

            expect(response).to have_gitlab_http_status(expected_status)
          end
        end
      end

      context 'when current_user has access' do
        before do
          stub_licensed_features(external_status_checks: true)
          project.add_member(user, :maintainer)
        end

        context 'when status check is failed' do
          let_it_be(:data) { merge_request.to_hook_data(user) }

          before do
            create(:status_check_response, merge_request: merge_request,
                                           external_status_check: rule, sha: merge_request.diff_head_sha, status: 'failed')
          end

          it 'calls async execute with correct data' do
            expect_next_found_instance_of(::MergeRequests::ExternalStatusCheck) do |instance|
              instance.to receive(:async_execute).with(data)
            end

            retry_failed_status_check
          end

          it 'returns accepted response' do
            retry_failed_status_check

            expect(response).to have_gitlab_http_status(:accepted)
          end
        end

        context 'when status check is passed' do
          before do
            create(:status_check_response, merge_request: merge_request,
                                           external_status_check: rule, sha: merge_request.diff_head_sha, status: 'passed')
          end

          it 'returns unprocessable_entity response', :aggregate_failures do
            retry_failed_status_check

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(response.body).to eq('{"message":"External status check must be failed"}')
          end
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
        put api(single_object_url, project.first_owner), params: params
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
          put api(single_object_url, project.first_owner), params: params
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
          put api(single_object_url, project.first_owner), params: params
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
          put api(single_object_url, (project_owner ? project.first_owner : build(:user))), params: attributes_for(:external_status_check)

          expect(response).to have_gitlab_http_status(status)
        end
      end
    end
  end
end
