# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Jobs, feature_category: :continuous_integration do
  let_it_be(:project) do
    create(:project, :repository, public_builds: false)
  end

  let_it_be(:pipeline) do
    create(:ci_pipeline, project: project,
                         sha: project.commit.id,
                         ref: project.default_branch)
  end

  let(:developer) { create(:user) }

  let(:download_headers) do
    { 'Content-Transfer-Encoding' => 'binary',
      'Content-Disposition' =>
    %Q(attachment; filename="#{job.artifacts_file.filename}"; filename*=UTF-8''#{job.artifacts_file.filename}) }
  end

  before do
    project.add_developer(developer)
  end

  describe 'GET /projects/:id/jobs/:job_id/artifacts' do
    let(:job) { create(:ci_build, :artifacts, pipeline: pipeline, user: api_user, status: :running) }

    context 'when using job_token to authenticate' do
      subject do
        get api("/projects/#{project.id}/jobs/#{job.id}/artifacts"), params: { job_token: job.token }
      end

      context 'when cross-project pipelines are enabled' do
        before do
          stub_licensed_features(cross_project_pipelines: true)
        end

        context 'user is developer' do
          let(:api_user) { developer }

          it 'returns specific job artifacts' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.headers.to_h).to include(download_headers)
            expect(response.body).to match_file(job.artifacts_file.file.file)
          end
        end

        context 'when anonymous user is accessing private artifacts' do
          let(:api_user) { nil }

          it 'hides artifacts and rejects request' do
            subject

            expect(project).to be_private
            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when cross-project pipeline are disabled' do
        let(:api_user) { developer }

        it 'disallows access to the artifacts' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when the job is not running' do
        let(:api_user) { developer }

        before do
          job.success!
        end

        it 'disallows access to the artifacts' do
          subject

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end
  end

  describe 'GET /projects/:id/artifacts/:ref_name/download?job=name' do
    let(:running_job) { create(:ci_build, :artifacts, pipeline: pipeline, user: api_user, status: :running) }
    let(:job) { create(:ci_build, :artifacts, pipeline: pipeline, user: api_user) }

    context 'when using job_token to authenticate' do
      subject do
        get api("/projects/#{project.id}/jobs/artifacts/#{pipeline.ref}/download"), params: { job: job.name, job_token: running_job.token }
      end

      context 'when cross-project pipelines are enabled' do
        before do
          stub_licensed_features(cross_project_pipelines: true)
        end

        context 'when user is developer' do
          let(:api_user) { developer }

          before do
            job.success
          end

          context 'when artifacts are stored locally' do
            it 'returns specific job artifacts', :sidekiq_might_not_need_inline do
              subject

              expect(response).to have_gitlab_http_status(:ok)
              expect(response.headers.to_h).to include(download_headers)
              expect(response.body).to match_file(job.artifacts_file.file.file)
            end
          end

          context 'when artifacts are stored remotely' do
            let(:job) { create(:ci_build, pipeline: pipeline, user: api_user) }

            before do
              stub_artifacts_object_storage
              job.job_artifacts << create(:ci_job_artifact, :archive, :remote_store)
            end

            subject { get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user) }

            it 'returns location redirect' do
              subject

              expect(response).to have_gitlab_http_status(:found)
            end
          end
        end

        context 'when user is admin, but not member' do
          let(:api_user) { create(:admin) }

          it 'does not allow to see that artfiact is present' do
            subject

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end
end
