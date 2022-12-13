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

  describe 'PATCH /api/v4/jobs/:id/trace' do
    let(:job) do
      create(:ci_build, :running, :trace_live,
        project: project,
        user: user,
        runner: runner,
        pipeline: pipeline)
    end

    it 'tracks CI minutes usage of running job' do
      expect(Ci::Minutes::TrackLiveConsumptionService).to receive(:new).with(job).and_call_original

      patch_the_trace
    end

    context 'when CI minutes usage is exceeded' do
      it 'drops the job' do
        freeze_time do
          Ci::Minutes::TrackLiveConsumptionService.new(job).time_last_tracked_consumption!(10.minutes.ago)
          patch_the_trace

          expect(response).to have_gitlab_http_status(:accepted)
          expect(response.header['Job-Status']).to eq('failed')
          expect(job.reload.trace.raw).to eq 'BUILD TRACE appended'
          expect(response.header).to have_key 'Range'
          expect(response.header).to have_key 'X-GitLab-Trace-Update-Interval'

          expect(job).to be_failed
          expect(job.failure_reason).to eq('ci_quota_exceeded')
        end
      end
    end

    context 'when CI minutes usage is not exceeded' do
      it 'does not drop the job' do
        freeze_time do
          Ci::Minutes::TrackLiveConsumptionService.new(job).time_last_tracked_consumption!(2.minutes.ago)
          patch_the_trace

          expect(response).to have_gitlab_http_status(:accepted)
          expect(response.header['Job-Status']).to eq('running')
          expect(job.reload.trace.raw).to eq 'BUILD TRACE appended'
          expect(response.header).to have_key 'Range'
          expect(response.header).to have_key 'X-GitLab-Trace-Update-Interval'
        end
      end
    end

    def patch_the_trace(content = ' appended')
      headers = { API::Ci::Helpers::Runner::JOB_TOKEN_HEADER => job.token, 'Content-Type' => 'text/plain' }

      job.trace.read do |stream|
        offset = stream.size
        limit = offset + content.length - 1
        headers = headers.merge({ 'Content-Range' => "#{offset}-#{limit}" })
      end

      patch api("/jobs/#{job.id}/trace"), params: content, headers: headers
      job.reload
    end
  end
end
