# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::MergeTrains, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:other_project) { create(:project, :repository) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:reporter) { create(:user) }

  let(:user) { developer }

  before do
    stub_feature_flags(disable_merge_trains: false)
    stub_licensed_features(merge_pipelines: true, merge_trains: true)
  end

  before_all do
    project.ci_cd_settings.update!(merge_pipelines_enabled: true, merge_trains_enabled: true)
    project.add_developer(developer)
    project.add_guest(guest)
    other_project.add_developer(developer)
    project.add_maintainer(maintainer)
    project.add_reporter(reporter)
  end

  describe 'GET /projects/:id/merge_trains' do
    subject { get api("/projects/#{project.id}/merge_trains", user), params: params }

    let(:params) { {} }

    context 'when there are two merge trains' do
      let_it_be(:train_car_1) { create(:merge_train_car, :merged, target_project: project) }
      let_it_be(:train_car_2) { create(:merge_train_car, :idle, target_project: project) }

      it 'returns merge trains sorted by id in descending order' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/merge_trains', dir: 'ee')
        expect(json_response.count).to eq(2)
        expect(json_response.first['id']).to eq(train_car_2.id)
        expect(json_response.second['id']).to eq(train_car_1.id)
      end

      it 'does not have N+1 problem' do
        control_count = ActiveRecord::QueryRecorder.new { subject }

        create_list(:merge_train_car, 3, target_project: project)

        expect { get api("/projects/#{project.id}/merge_trains", user) }
          .not_to exceed_query_limit(control_count)
      end

      context 'when sort is specified' do
        let(:params) { { sort: 'asc' } }

        it 'returns merge trains sorted by id in ascending order' do
          subject

          expect(json_response.first['id']).to eq(train_car_1.id)
          expect(json_response.second['id']).to eq(train_car_2.id)
        end
      end

      context 'when scope is specified' do
        context 'when scope is active' do
          let(:params) { { scope: 'active' } }

          it 'returns active merge trains' do
            subject

            expect(json_response.count).to eq(1)
            expect(json_response.first['id']).to eq(train_car_2.id)
          end
        end

        context 'when scope is complete' do
          let(:params) { { scope: 'complete' } }

          it 'returns complete merge trains' do
            subject

            expect(json_response.count).to eq(1)
            expect(json_response.first['id']).to eq(train_car_1.id)
          end
        end
      end

      context 'when user is guest' do
        let(:user) { guest }

        it 'forbids the request' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  describe 'GET /projects/:id/merge_trains/:target_branch' do
    let!(:train_car_1) { create(:merge_train_car, :idle, target_project: project, target_branch: 'master') }
    let!(:train_car_2) { create(:merge_train_car, :merged, target_project: project, target_branch: 'master') }
    let!(:train_car_3) { create(:merge_train_car, target_project: project, target_branch: 'feature') }
    let!(:train_car_4) { create(:merge_train_car, target_project: other_project, target_branch: 'master') }

    context 'when the project and target branch exist' do
      subject do
        get api("/projects/#{project.id}/merge_trains/#{train_car_1.target_branch}", developer), params: params
      end

      context 'with no params' do
        let(:params) { {} }

        it 'returns the target branch merge train cars' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.count).to eq(2)
        end
      end

      context 'with ascending sort' do
        let(:params) { { sort: 'asc' } }

        it 'returns the target branch merge train cars ascending' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.count).to eq(2)
          expect(json_response.first['id']).to eq(train_car_1.id)
          expect(json_response.second['id']).to eq(train_car_2.id)
        end
      end

      context 'with descending sort' do
        let(:params) { { sort: 'desc' } }

        it 'returns the target branch merge train cars descending' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.count).to eq(2)
          expect(json_response.first['id']).to eq(train_car_2.id)
          expect(json_response.second['id']).to eq(train_car_1.id)
        end
      end

      context 'with scope active' do
        let(:params) { { scope: 'active' } }

        it 'returns the active target branch merge train cars' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.count).to eq(1)
          expect(json_response.first['id']).to eq(train_car_1.id)
        end
      end
    end

    context 'when the target branch does not exist' do
      subject { get api("/projects/#{project.id}/merge_trains/random", developer) }

      it 'returns no merge train cars' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.count).to eq(0)
      end
    end

    context 'when the user does not have project access' do
      subject { get api("/projects/#{project.id}/merge_trains/#{train_car_1.target_branch}", guest) }

      it 'returns forbidden' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'GET /projects/:id/merge_trains/merge_requests/:merge_request_iid' do
    let(:merge_request_1) do
      create(:merge_request, :with_merge_request_pipeline,
             source_project: project, source_branch: 'feature',
             target_project: project, target_branch: 'master', title: 'Test')
    end

    let!(:train_car_1) { create(:merge_train_car, merge_request: merge_request_1) }

    context 'when the project and target branch exist' do
      subject { get api("/projects/#{project.id}/merge_trains/merge_requests/#{merge_request_1.iid}", developer) }

      it 'returns the target branch merge train cars' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response["id"]).to eq(train_car_1.id)
        expect(json_response["merge_request"]["iid"]).to eq(merge_request_1.iid)
      end
    end

    context 'when the user does not have project access' do
      subject { get api("/projects/#{project.id}/merge_trains/merge_requests/#{merge_request_1.iid}", guest) }

      it 'returns forbidden' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when the merge request does not exist' do
      subject { get api("/projects/#{project.id}/merge_trains/merge_requests/50", developer) }

      it 'returns not found' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when merge request is not in a merge train' do
      let(:merge_request_2) do
        create(:merge_request, source_project: project, source_branch: 'second',
                               target_project: project, target_branch: 'master')
      end

      subject { get api("/projects/#{project.id}/merge_trains/merge_requests/#{merge_request_2.iid}", developer) }

      it 'returns not found' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /projects/:id/merge_trains/merge_requests/:merge_request_iid' do
    let(:merge_request) do
      create(:merge_request,
             source_project: project, source_branch: 'feature',
             target_project: project, target_branch: 'master',
             merge_status: 'unchecked')
    end

    let(:params) { {} }
    let(:pipeline_status) { :success }
    let(:user) { maintainer }
    let(:merge_request_iid) { merge_request.iid }

    let(:ci_yaml) do
      { test: { stage: 'test', script: 'echo', only: ['merge_requests'] } }
    end

    subject do
      post api("/projects/#{project.id}/merge_trains/merge_requests/#{merge_request_iid}", user),
        params: params
    end

    before do
      create(:ci_pipeline, pipeline_status, ref: merge_request.source_branch,
                                            sha: merge_request.diff_head_sha,
                                            project: merge_request.source_project)

      merge_request.update_head_pipeline
    end

    shared_examples 'succeeds to add to merge train' do
      it 'succeeds to add to merge train' do
        subject

        expect(response).to have_gitlab_http_status(:created)
      end
    end

    context 'with valid merge request iid' do
      let(:merge_request_iid) { merge_request.iid }

      it_behaves_like 'succeeds to add to merge train'
    end

    context 'with invalid merge request iid' do
      let(:merge_request_iid) { -1 }

      it 'exits with invalid return code' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with no params' do
      let(:params) { {} }

      it_behaves_like 'succeeds to add to merge train'
    end

    context 'with valid parameters' do
      let(:params) { { sha: merge_request.diff_head_sha, squash: true, when_pipeline_succeeds: false } }

      it_behaves_like 'succeeds to add to merge train'
    end

    context 'with extra parameters' do
      let(:params) { { extra_param: true } }

      it 'ignores the param and continues' do
        subject

        expect(response).to have_gitlab_http_status(:created)
      end
    end

    context 'with when_pipeline_succeeds enabled' do
      let(:params) { { when_pipeline_succeeds: true } }

      context 'when pipeline is not completed' do
        let(:pipeline_status) { :running }

        it 'returns status accepted' do
          subject

          expect(response).to have_gitlab_http_status(:accepted)
        end
      end
    end

    context 'when sha is provided and matches' do
      let(:params) { { sha: merge_request.diff_head_sha } }

      it_behaves_like 'succeeds to add to merge train'
    end

    context 'when sha is provided and doesn\'t match' do
      let(:params) { { sha: 'SomeFakeSha' } }

      it 'returns status conflict' do
        subject

        expect(response).to have_gitlab_http_status(:conflict)
      end
    end

    context 'when user is guest' do
      let(:user) { guest }

      it 'returns forbidden before reaching the api endpoint' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when the service object fails' do
      let(:user) { reporter }

      it 'returns status unauthorized' do
        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when the service object returns an unexpected response' do
      it 'returns bad request' do
        expect_next_instance_of(::MergeTrains::AddMergeRequestService) do |service|
          expect(service).to receive(:execute).and_return(
            ServiceResponse.error(
              message: "Unexpected service response"
            ))
        end

        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end
end
