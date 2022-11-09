# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Pipeline::Chain::Limit::Size, :saas do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:project, reload: true) { create(:project, :repository, namespace: namespace) }
  let_it_be(:user) { create(:user) }

  let(:pipeline) { build(:ci_pipeline, project: project) }

  let(:command) do
    double(:command,
      project: project,
      current_user: user,
      pipeline_seed: double(:seed, size: 1))
  end

  let(:step) { described_class.new(pipeline, command) }

  subject { step.perform! }

  context 'when pipeline size limit is exceeded' do
    before do
      ultimate_plan = create(:ultimate_plan)
      create(:plan_limits, plan: ultimate_plan, ci_pipeline_size: 1)
      create(:gitlab_subscription, namespace: namespace, hosted_plan: ultimate_plan)
    end

    context 'when saving incomplete pipelines' do
      let(:command) do
        double(:command,
          project: project,
          current_user: user,
          save_incompleted: true,
          pipeline_seed: double(:seed, size: 2))
      end

      it 'drops the pipeline' do
        subject

        expect(pipeline.reload).to be_failed
      end

      it 'persists the pipeline' do
        subject

        expect(pipeline).to be_persisted
      end

      it 'breaks the chain' do
        subject

        expect(step.break?).to be true
      end

      it 'sets a valid failure reason' do
        subject

        expect(pipeline.size_limit_exceeded?).to be true
      end

      it 'appends validation error' do
        subject

        expect(pipeline.errors.to_a)
          .to include "The number of jobs has exceeded the limit of 1."\
          " Try splitting the configuration with parent-child-pipelines"\
          " https://docs.gitlab.com/ee/ci/troubleshooting.html#pipeline-with-many-jobs-fails-to-start"
      end

      it 'logs the error' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          instance_of(Gitlab::Ci::Limit::LimitExceededError),
          {
            jobs_count: pipeline.statuses.count,
            project_id: project.id, plan: namespace.actual_plan_name,
            project_full_path: project.full_path, pipeline_source: pipeline.source
          }
        )

        subject
      end
    end

    context 'when not saving incomplete pipelines' do
      let(:command) do
        double(:command,
          project: project,
          current_user: user,
          save_incompleted: false,
          pipeline_seed: double(:seed, size: 2),
          increment_pipeline_failure_reason_counter: true)
      end

      it 'does not drop the pipeline' do
        subject

        expect(pipeline).not_to be_failed
      end

      it 'breaks the chain' do
        subject

        expect(step.break?).to be true
      end

      it 'increments the error metric' do
        expect(command).to receive(:increment_pipeline_failure_reason_counter).with(:size_limit_exceeded)

        subject
      end
    end
  end

  context 'when pipeline size limit is not exceeded' do
    before do
      ultimate_plan = create(:ultimate_plan)
      create(:plan_limits, plan: ultimate_plan, ci_pipeline_size: 100)
      create(:gitlab_subscription, namespace: namespace, hosted_plan: ultimate_plan)
    end

    it 'does not break the chain' do
      subject

      expect(step.break?).to be false
    end

    it 'does not persist the pipeline' do
      subject

      expect(pipeline).not_to be_persisted
    end

    it 'does not log any error' do
      expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

      subject
    end
  end

  context 'when pipeline size limit is disabled' do
    before do
      ultimate_plan = create(:ultimate_plan)
      create(:plan_limits, plan: ultimate_plan, ci_pipeline_size: 0)
      create(:gitlab_subscription, namespace: namespace, hosted_plan: ultimate_plan)
    end

    context 'when global pipeline size limit is exceeded' do
      let(:command) do
        double(:command,
          project: project,
          current_user: user,
          pipeline_seed: double(:seed, size: 2001))
      end

      it 'logs the pipeline' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          instance_of(Gitlab::Ci::Limit::LimitExceededError),
          {
            jobs_count: pipeline.statuses.count,
            project_id: project.id, plan: namespace.actual_plan_name,
            project_full_path: project.full_path, pipeline_source: pipeline.source
          }
        )

        subject
      end
    end
  end
end
