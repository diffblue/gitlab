# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Runner, :clean_gitlab_redis_shared_state, feature_category: :runner do
  let_it_be(:minutes_used) { 95 + Ci::Minutes::TrackLiveConsumptionService::CONSUMPTION_THRESHOLD.abs }
  let_it_be(:group) { create(:group, :with_ci_minutes, ci_minutes_limit: 100, ci_minutes_used: minutes_used) }
  let_it_be(:project) { create(:project, :private, namespace: group, shared_runners_enabled: true) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: 'master') }
  let_it_be(:runner) { create(:ci_runner, :instance) }
  let_it_be(:user) { create(:user) }

  let(:headers) { { API::Ci::Helpers::Runner::JOB_TOKEN_HEADER => job.token, 'Content-Type' => 'text/plain' } }

  before do
    allow(Gitlab).to receive(:com?).and_return(true)
  end

  describe 'PUT /api/v4/jobs/:id' do
    let(:job) do
      create(:ci_build, :running, :trace_live,
        project: project,
        user: user,
        runner: runner,
        pipeline: pipeline)
    end

    it 'tracks CI minutes usage of running job' do
      expect(Ci::Minutes::TrackLiveConsumptionService).to receive(:new).with(job).and_call_original

      update_job(state: 'running')
    end

    context 'when CI minutes usage is exceeded' do
      it 'drops the job' do
        freeze_time do
          Ci::Minutes::TrackLiveConsumptionService.new(job).time_last_tracked_consumption!(10.minutes.ago)
          update_job(state: 'running')

          expect(response).to have_gitlab_http_status(:ok)

          expect(job.reload).to be_failed
          expect(job.failure_reason).to eq('ci_quota_exceeded')
        end
      end
    end

    context 'when CI minutes usage is not exceeded' do
      it 'does not drop the job' do
        freeze_time do
          Ci::Minutes::TrackLiveConsumptionService.new(job).time_last_tracked_consumption!(2.minutes.ago)

          update_job(state: 'running')

          expect(response).to have_gitlab_http_status(:ok)

          expect(job.reload).to be_running
        end
      end
    end

    def update_job(token = job.token, **params)
      new_params = params.merge(token: token)
      put api("/jobs/#{job.id}"), params: new_params
    end
  end
end
