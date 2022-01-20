# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Runner do
  let_it_be(:project) { create(:project, :repository) }

  describe '/api/v4/jobs' do
    let(:runner) { create(:ci_runner, :project, projects: [project]) }

    describe 'POST /api/v4/jobs/request' do
      context 'secrets management' do
        let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master') }
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
    end

    def request_job(token = runner.token, **params)
      post api('/jobs/request'), params: params.merge(token: token)
    end
  end
end
