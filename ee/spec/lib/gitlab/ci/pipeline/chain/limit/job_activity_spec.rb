# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Pipeline::Chain::Limit::JobActivity, :saas do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:project) { create(:project, namespace: namespace) }
  let_it_be(:user) { create(:user) }

  let(:command) do
    instance_double(
      ::Gitlab::Ci::Pipeline::Chain::Command,
      project: project,
      current_user: user,
      limit_active_jobs_early?: feature_flag_enabled)
  end

  let(:pipeline) do
    create(:ci_pipeline, project: project)
  end

  let(:step) { described_class.new(pipeline, command) }
  let(:feature_flag_enabled) { false }

  subject { step.perform! }

  context 'when active jobs limit is exceeded' do
    before do
      ultimate_plan = create(:ultimate_plan)
      create(:plan_limits, plan: ultimate_plan, ci_active_jobs: 2)
      create(:gitlab_subscription, namespace: namespace, hosted_plan: ultimate_plan)

      pipeline = create(:ci_pipeline, project: project, status: 'running', created_at: Time.current)
      create(:ci_build, pipeline: pipeline)
      create(:ci_build, pipeline: pipeline)
      create(:ci_build, pipeline: pipeline)
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

      expect(pipeline.job_activity_limit_exceeded?).to be true
    end

    it 'logs the error' do
      expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
        instance_of(Gitlab::Ci::Limit::LimitExceededError),
        { project_id: project.id, plan: namespace.actual_plan_name }
      )

      subject
    end

    context 'when feature flag ci_limit_active_jobs_early is enabled' do
      let(:feature_flag_enabled) { true }

      it 'skips this step' do
        subject

        expect(pipeline).not_to be_failed
        expect(pipeline.job_activity_limit_exceeded?).to be false
        expect(step.break?).to be false
      end
    end
  end

  context 'when job activity limit is not exceeded' do
    before do
      ultimate_plan = create(:ultimate_plan)
      create(:plan_limits, plan: ultimate_plan, ci_active_jobs: 100)
      create(:gitlab_subscription, namespace: namespace, hosted_plan: ultimate_plan)
    end

    it 'does not break the chain' do
      subject

      expect(step.break?).to be false
    end

    it 'does not invalidate the pipeline' do
      subject

      expect(pipeline.errors).to be_empty
    end

    it 'does not log any error' do
      expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

      subject
    end

    context 'when feature flag ci_limit_active_jobs_early is enabled' do
      let(:feature_flag_enabled) { true }

      it 'skips this step' do
        expect_next_instance_of(EE::Gitlab::Ci::Pipeline::Quota::JobActivity) do |limit|
          expect(limit).not_to receive(:exceeded?)
        end

        subject
      end
    end
  end
end
