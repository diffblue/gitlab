# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::JobsController, feature_category: :continuous_integration do
  describe 'GET #show', :clean_gitlab_redis_shared_state do
    context 'when requesting JSON' do
      let_it_be(:user) { create(:user) }

      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:runner) { create(:ci_runner, :instance, description: 'Shared runner') }
      let(:pipeline) { create(:ci_pipeline, project: project) }
      let(:job) { create(:ci_build, :success, :artifacts, pipeline: pipeline, runner: runner) }

      before do
        project.add_developer(user)
        sign_in(user)

        allow_next_instance_of(Ci::Build) do |instance|
          allow(instance).to receive(:merge_request).and_return(merge_request)
        end
      end

      context 'with shared runner that has quota' do
        let(:project) { create(:project, :repository, :private, shared_runners_enabled: true) }

        before do
          stub_application_setting(shared_runners_minutes: 2)

          get_show(id: job.id, format: :json)
        end

        it 'exposes quota information' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('job/job_details', dir: 'ee')
          expect(json_response['runners']['quota']['used']).to eq 0
          expect(json_response['runners']['quota']['limit']).to eq 2
        end
      end

      context 'with shared runner quota exceeded' do
        let(:group) { create(:group, :with_used_build_minutes_limit) }
        let(:project) { create(:project, :repository, namespace: group, shared_runners_enabled: true) }

        before do
          get_show(id: job.id, format: :json)
        end

        it 'exposes quota information' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('job/job_details', dir: 'ee')
          expect(json_response['runners']['quota']['used']).to eq 1000
          expect(json_response['runners']['quota']['limit']).to eq 500
        end
      end

      context 'when shared runner has no quota' do
        let(:project) { create(:project, :repository, :private, shared_runners_enabled: true) }

        before do
          stub_application_setting(shared_runners_minutes: 0)

          get_show(id: job.id, format: :json)
        end

        it 'does not exposes quota information' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('job/job_details', dir: 'ee')
          expect(json_response['runners']).not_to have_key('quota')
        end
      end

      context 'when project is public' do
        let(:project) { create(:project, :repository, :public, shared_runners_enabled: true) }

        before do
          stub_application_setting(shared_runners_minutes: 2)
        end

        it 'exposes quota information' do
          get_show(id: job.id, format: :json)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('job/job_details', dir: 'ee')
          expect(json_response['runners']['quota']['used']).to eq 0
          expect(json_response['runners']['quota']['limit']).to eq 2
        end

        context 'the environment is protected' do
          before do
            stub_licensed_features(protected_environments: true)
            create(:protected_environment, project: project)
          end

          let(:job) { create(:ci_build, :deploy_to_production, :with_deployment, :success, pipeline: pipeline, runner: runner) }

          it 'renders successfully' do
            get_show(id: job.id, format: :json)

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('job/job_details', dir: 'ee')
          end

          context 'anonymous user' do
            before do
              sign_out(user)
            end

            it 'renders successfully' do
              get_show(id: job.id, format: :json)

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to match_response_schema('job/job_details', dir: 'ee')
            end
          end
        end
      end

      context 'when project is private' do
        let_it_be(:project) { create(:project, :private) }

        subject { get_show(id: job.id, format: :json) }

        shared_examples 'returns nil quota' do
          it 'returns no quota for the runner' do
            subject

            expect(json_response['runners']['quota']).to eq nil
          end
        end

        shared_examples 'returns quota' do
          it 'returns a quota' do
            subject

            expect(json_response['runners']['quota']).to eq(
              { 'used' => 0, 'limit' => project.root_namespace.shared_runners_minutes_limit }
            )
          end
        end

        shared_context 'with quota enabled' do
          before do
            project.update!(shared_runners_enabled: true)
            project.root_namespace.update!(shared_runners_minutes_limit: 500)
          end
        end

        context 'when user has read_ci_minutes_limited_summary permissions' do
          before do
            project.add_reporter(user)
          end

          it_behaves_like 'returns nil quota'

          context 'with shared_runners_minutes_limit_enabled' do
            include_context 'with quota enabled'

            it_behaves_like 'returns quota'
          end
        end

        context 'when user does not have read_ci_minutes_limited_summary permissions' do
          before do
            project.add_guest(user)
          end

          it_behaves_like 'returns nil quota'

          context 'with shared_runners_minutes_limit_enabled' do
            include_context 'with quota enabled'

            it_behaves_like 'returns nil quota'
          end
        end
      end
    end

    private

    def get_show(**extra_params)
      params = {
          namespace_id: project.namespace.to_param,
          project_id: project
      }

      get :show, params: params.merge(extra_params)
    end
  end
end
