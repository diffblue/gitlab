# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Pipeline::Metrics do
  describe '.pipeline_creation_step_duration_histogram' do
    it 'adds the step to the step duration histogram' do
      step = 'gitlab_ci_pipeline_chain_build'

      expect(::Gitlab::Metrics).to receive(:histogram)
        .with(
          :gitlab_ci_pipeline_chain_build_duration_seconds,
          'Duration of the pipeline chain build',
          {},
          [0.01, 0.05, 0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 15.0, 20.0, 50.0, 240.0]
        )

      described_class.pipeline_creation_step_duration_histogram(step)
    end
  end
end
