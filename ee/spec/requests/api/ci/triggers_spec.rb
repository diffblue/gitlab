# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Triggers do
  include AfterNextHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :auto_devops, creator: user) }
  let_it_be(:other_project) { create(:project) }

  describe 'POST /projects/:project_id/trigger/pipeline' do
    context 'when triggering a pipeline from a job token' do
      let(:other_job) { create(:ci_build, :running, user: other_user, project: other_project) }
      let(:params) { { ref: 'refs/heads/other-branch' } }

      subject do
        post api("/projects/#{project.id}/ref/master/trigger/pipeline?token=#{other_job.token}"), params: params
      end

      before do
        allow_next(Ci::JobToken::Scope).to receive(:includes?).with(project).and_return(true)
      end

      context 'without user' do
        let(:other_user) { nil }

        it 'does not leak the presence of project when using valid token' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'for unreleated user' do
        let(:other_user) { create(:user) }

        it 'does not leak the presence of project when using valid token' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'for related user' do
        let(:other_user) { create(:user) }

        context 'with reporter permissions' do
          before do
            project.add_reporter(other_user)
          end

          it 'forbids to create a pipeline' do
            subject

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to eq("base" => ["Insufficient permissions to create a new pipeline"])
          end
        end

        context 'with developer permissions' do
          before do
            project.add_developer(other_user)
          end

          it 'creates a new pipeline' do
            expect { subject }.to change(Ci::Pipeline, :count)

            expect(response).to have_gitlab_http_status(:created)
            expect(Ci::Pipeline.last.source).to eq('pipeline')
            expect(Ci::Pipeline.last.triggered_by_pipeline).not_to be_nil
            expect(Ci::Sources::Pipeline.last).to have_attributes(
              pipeline_id: (a_value > 0),
              source_pipeline_id: (a_value > 0),
              source_job_id: (a_value > 0),
              source_project_id: (a_value > 0)
            )
          end

          context 'when project is not in the job token scope' do
            before do
              allow_next(Ci::JobToken::Scope)
                .to receive(:includes?)
                .with(project)
                .and_return(false)
            end

            it 'forbids to create a pipeline' do
              subject

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end

          context 'when build is complete' do
            before do
              other_job.success
            end

            it 'does not create a pipeline' do
              subject

              expect(response).to have_gitlab_http_status(:unauthorized)
              expect(json_response['message']).to eq('Job is not running')
            end
          end

          context 'when variables are defined' do
            let(:params) do
              { ref: 'refs/heads/other-branch',
                variables: { 'KEY' => 'VALUE' } }
            end

            it 'creates a new pipeline with a variable' do
              expect { subject }.to change(Ci::Pipeline, :count)
                                .and change(Ci::PipelineVariable, :count)

              expect(response).to have_gitlab_http_status(:created)
              expect(Ci::Pipeline.last.source).to eq('pipeline')
              expect(Ci::Pipeline.last.triggered_by_pipeline).not_to be_nil
              expect(Ci::Pipeline.last.variables.find { |v| v.key == 'KEY' }.value).to eq('VALUE')
            end
          end
        end
      end
    end
  end
end
