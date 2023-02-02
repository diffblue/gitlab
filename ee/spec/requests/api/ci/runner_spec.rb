# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Runner, feature_category: :runner do
  include Ci::JobTokenScopeHelpers

  let_it_be_with_reload(:project) { create(:project, :repository) }

  let_it_be(:user) { create(:user) }
  let_it_be(:ref) { 'master' }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: ref) }
  let_it_be(:runner) { create(:ci_runner, :project, projects: [project]) }

  before_all do
    project.add_developer(user)
  end

  describe '/api/v4/jobs', feature_category: :continuous_integration do
    describe 'POST /api/v4/jobs/request' do
      context 'secrets management' do
        let(:valid_secrets) do
          {
            DATABASE_PASSWORD: {
              vault: {
                engine: { name: 'kv-v2', path: 'kv-v2' },
                path: 'production/db',
                field: 'password'
              },
              file: true
            }
          }
        end

        let!(:ci_build) { create(:ci_build, :pending, :queued, pipeline: pipeline, secrets: secrets) }

        context 'when secrets management feature is available' do
          before do
            stub_licensed_features(ci_secrets_management: true)
          end

          context 'when job has secrets configured' do
            let(:secrets) { valid_secrets }

            context 'when runner does not support secrets' do
              it 'sets "runner_unsupported" failure reason and does not expose the build at all' do
                request_job

                expect(ci_build.reload).to be_runner_unsupported
                expect(response).to have_gitlab_http_status(:no_content)
              end
            end

            context 'when runner supports secrets' do
              before do
                create(:ci_variable, project: project, key: 'VAULT_SERVER_URL', value: 'https://vault.example.com')
                create(:ci_variable, project: project, key: 'VAULT_AUTH_ROLE', value: 'production')
              end

              it 'returns secrets configuration' do
                request_job_with_secrets_supported

                expect(response).to have_gitlab_http_status(:created)
                expect(json_response['secrets']).to eq(
                  {
                    'DATABASE_PASSWORD' => {
                      'vault' => {
                        'server' => {
                          'url' => 'https://vault.example.com',
                          'namespace' => nil,
                          'auth' => {
                            'name' => 'jwt',
                            'path' => 'jwt',
                            'data' => {
                              'jwt' => '${CI_JOB_JWT}',
                              'role' => 'production'
                            }
                          }
                        },
                        'engine' => { 'name' => 'kv-v2', 'path' => 'kv-v2' },
                        'path' => 'production/db',
                        'field' => 'password'
                      },
                      'file' => true
                    }
                  }
                )
              end
            end
          end

          context 'job does not have secrets configured' do
            let(:secrets) { {} }

            it 'doesn not return secrets configuration' do
              request_job_with_secrets_supported

              expect(response).to have_gitlab_http_status(:created)
              expect(json_response['secrets']).to eq({})
            end
          end
        end

        context 'when secrets management feature is not available' do
          before do
            stub_licensed_features(ci_secrets_management: false)
          end

          context 'job has secrets configured' do
            let(:secrets) { valid_secrets }

            it 'does not return secrets configuration' do
              request_job_with_secrets_supported

              expect(response).to have_gitlab_http_status(:created)
              expect(json_response['secrets']).to eq(nil)
            end
          end
        end
      end

      def request_job_with_secrets_supported
        request_job info: { features: { vault_secrets: true } }
      end

      def request_job(token = runner.token, **params)
        post api('/jobs/request'), params: params.merge(token: token)
      end
    end

    describe 'GET api/v4/jobs/:id/artifacts' do
      let_it_be(:job) { create(:ci_build, :success, ref: ref, pipeline: pipeline, user: user, project: project) }

      before_all do
        create(:ci_job_artifact, :archive, job: job, project: project)
      end

      shared_examples 'successful artifact download' do
        it 'downloads artifacts' do
          download_artifact

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      shared_examples 'forbidden request' do
        it 'responds with forbidden' do
          download_artifact

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when a job has a cross-project dependency' do
        let_it_be(:downstream_project) { create(:project) }
        let_it_be_with_reload(:downstream_project_dev) { create(:user) }

        let_it_be(:options) do
          {
            cross_dependencies: [
              {
                project: project.full_path,
                ref: ref,
                job: job.name,
                artifacts: true
              }
            ]

          }
        end

        let_it_be_with_reload(:downstream_ci_build) do
          create(:ci_build, :running, project: downstream_project, user: user, options: options)
        end

        let(:token) { downstream_ci_build.token }

        before_all do
          downstream_project.add_developer(user)
          downstream_project.add_developer(downstream_project_dev)
          make_project_fully_accessible(downstream_project, project)
        end

        before do
          stub_licensed_features(cross_project_pipelines: true)
        end

        context 'when the job is created by a user with sufficient permission in upstream project' do
          it_behaves_like 'successful artifact download'

          context 'and the upstream project has disabled public builds' do
            before do
              project.update!(public_builds: false)
            end

            it_behaves_like 'successful artifact download'
          end
        end

        context 'when the job is created by a user without sufficient permission in upstream project' do
          before do
            downstream_ci_build.update!(user: downstream_project_dev)
          end

          it_behaves_like 'forbidden request'

          context 'and the upstream project has disabled public builds' do
            before do
              project.update!(public_builds: false)
            end

            it_behaves_like 'forbidden request'
          end
        end

        context 'when the upstream project is public and the job user does not have permission in the project' do
          before do
            project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
            downstream_ci_build.update!(user: downstream_project_dev)
          end

          it_behaves_like 'successful artifact download'

          context 'and the upstream project has disabled public builds' do
            before do
              project.update!(public_builds: false)
            end

            it_behaves_like 'forbidden request'
          end
        end
      end

      def download_artifact(params = {}, request_headers = headers)
        params = params.merge(token: token)
        job.reload

        get api("/jobs/#{job.id}/artifacts"), params: params, headers: request_headers
      end
    end
  end
end
