# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::InitialPipelineProcessWorker, feature_category: :continuous_integration do
  describe '#perform' do
    let_it_be(:namespace) { create(:namespace, :with_used_build_minutes_limit) }
    let_it_be(:project) { create(:project, namespace: namespace) }
    let_it_be_with_reload(:pipeline) do
      create(:ci_pipeline, :with_job, project: project, status: :created)
    end

    let_it_be(:instance_runner) { create(:ci_runner, :instance, :online) }

    include_examples 'an idempotent worker' do
      let(:job_args) { pipeline.id }

      context 'when the project is out of CI minutes' do
        it 'marks the pipeline as failed' do
          expect(pipeline).to be_created

          subject

          expect(pipeline.reload).to be_failed
        end
      end
    end
  end
end
