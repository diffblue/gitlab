# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifacts::DestroyAllExpiredService, :clean_gitlab_redis_shared_state,
  feature_category: :build_artifacts do
  include ExclusiveLeaseHelpers

  describe '.execute' do
    subject { service.execute }

    let(:service) { described_class.new }

    let_it_be(:locked_pipeline) { create(:ci_pipeline, :artifacts_locked) }
    let_it_be(:pipeline) { create(:ci_pipeline, :unlocked) }
    let_it_be(:locked_job) { create(:ci_build, :success, pipeline: locked_pipeline) }
    let_it_be(:job) { create(:ci_build, :success, pipeline: pipeline) }

    context 'when artifact is expired' do
      context 'when artifact is not locked' do
        let!(:artifact) { create(:ci_job_artifact, :expired, job: job, locked: job.pipeline.locked) }
        let(:event_data) { { job_ids: [artifact.job_id] } }

        it 'destroys job artifact', :sidekiq_inline do
          expect { subject }.to change { Ci::JobArtifact.count }.by(-1)
        end

        it 'publishes Ci::JobArtifactsDeletedEvent' do
          expect { subject }.to publish_event(Ci::JobArtifactsDeletedEvent).with(event_data)
        end
      end

      context 'when artifact is locked' do
        let!(:artifact) { create(:ci_job_artifact, :expired, job: locked_job, locked: locked_job.pipeline.locked) }

        it 'does not destroy job artifact' do
          expect { subject }.to not_change { Ci::JobArtifact.count }
        end
      end
    end

    context 'when artifact is not expired' do
      let!(:artifact) { create(:ci_job_artifact, job: job, locked: job.pipeline.locked) }

      it 'does not destroy expired job artifacts' do
        expect { subject }.to not_change { Ci::JobArtifact.count }
      end
    end

    context 'when artifact is permanent' do
      let!(:artifact) { create(:ci_job_artifact, expire_at: nil, job: job, locked: job.pipeline.locked) }

      it 'does not destroy expired job artifacts' do
        expect { subject }.to not_change { Ci::JobArtifact.count }
      end
    end

    context 'when there are artifacts more than batch sizes' do
      before do
        stub_const('Ci::JobArtifacts::DestroyAllExpiredService::BATCH_SIZE', 1)
      end

      let!(:artifact) { create(:ci_job_artifact, :expired, job: job, locked: job.pipeline.locked) }
      let!(:second_job) { create(:ci_build, :success, pipeline: pipeline) }
      let!(:second_artifact) { create(:ci_job_artifact, :expired, job: second_job, locked: second_job.pipeline.locked) }

      it 'destroys all expired artifacts', :sidekiq_inline do
        expect { subject }.to change { Ci::JobArtifact.count }.by(-2)
      end
    end

    context 'when some artifacts are locked', :sidekiq_inline do
      let!(:artifact) { create(:ci_job_artifact, :expired, job: job, locked: job.pipeline.locked) }
      let!(:second_artifact) { create(:ci_job_artifact, :expired, job: locked_job, locked: locked_job.pipeline.locked) }

      it 'destroys only unlocked artifacts' do
        expect { subject }.to change { Ci::JobArtifact.count }.by(-1)
      end
    end
  end
end
