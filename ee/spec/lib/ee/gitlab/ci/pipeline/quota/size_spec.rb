# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Gitlab::Ci::Pipeline::Quota::Size, :saas do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:ultimate_plan, reload: true) { create(:ultimate_plan) }
  let_it_be(:project, reload: true) { create(:project, :repository, namespace: namespace) }
  let_it_be(:plan_limits) { create(:plan_limits, plan: ultimate_plan) }

  let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: ultimate_plan) }

  let(:pipeline) { build_stubbed(:ci_pipeline, project: project) }

  let(:command) do
    double(:command, pipeline_seed: double(:pipeline_seed, size: 2))
  end

  subject { described_class.new(namespace, pipeline, command) }

  shared_context 'pipeline size limit exceeded' do
    before do
      plan_limits.update!(ci_pipeline_size: 1)
    end
  end

  shared_context 'pipeline size limit not exceeded' do
    before do
      plan_limits.update!(ci_pipeline_size: 2)
    end
  end

  describe '#enabled?' do
    context 'when limit is enabled in plan' do
      before do
        plan_limits.update!(ci_pipeline_size: 10)
      end

      it 'is enabled' do
        expect(subject).to be_enabled
      end
    end

    context 'when limit is not enabled' do
      before do
        plan_limits.update!(ci_pipeline_size: 0)
      end

      it 'is not enabled' do
        expect(subject).not_to be_enabled
      end
    end

    context 'when limit does not exist' do
      before do
        allow(namespace).to receive(:actual_plan) { create(:default_plan) }
      end

      it 'is not enabled' do
        expect(subject).not_to be_enabled
      end
    end
  end

  describe '#exceeded?' do
    context 'when limit is exceeded' do
      include_context 'pipeline size limit exceeded'

      it 'is exceeded' do
        expect(subject).to be_exceeded
      end
    end

    context 'when limit is not exceeded' do
      include_context 'pipeline size limit not exceeded'

      it 'is not exceeded' do
        expect(subject).not_to be_exceeded
      end
    end
  end

  describe '#message' do
    context 'when limit is exceeded' do
      include_context 'pipeline size limit exceeded'

      it 'returns info about pipeline size limit exceeded' do
        expect(subject.message)
          .to eq "The number of jobs has exceeded the limit of 1."\
          " Try splitting the configuration with parent-child-pipelines"\
          " https://docs.gitlab.com/ee/ci/troubleshooting.html#pipeline-with-many-jobs-fails-to-start"
      end
    end
  end

  describe '#log_exceeded_limit?' do
    context 'when there are more than 2000 jobs in the pipeline' do
      let(:command) do
        double(:command, pipeline_seed: double(:pipeline_seed, size: 2001))
      end

      it 'returns true' do
        expect(subject.log_exceeded_limit?).to be_truthy
      end
    end

    context 'when there are 2000 or less jobs in the pipeline' do
      let(:command) do
        double(:command, pipeline_seed: double(:pipeline_seed, size: 2000))
      end

      it 'returns false' do
        expect(subject.log_exceeded_limit?).to be_falsey
      end
    end
  end
end
