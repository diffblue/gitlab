# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Pipeline::Chain::Limit::Activity do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:project) { create(:project, namespace: namespace) }
  let_it_be(:user) { create(:user) }

  let(:command) do
    double('command', project: project, current_user: user)
  end

  let(:pipeline) do
    create(:ci_pipeline, project: project)
  end

  let(:step) { described_class.new(pipeline, command) }

  subject { step.perform! }

  context 'when active pipelines limit is exceeded' do
    before do
      ultimate_plan = create(:ultimate_plan)
      create(:plan_limits, plan: ultimate_plan, ci_active_pipelines: 1)
      create(:gitlab_subscription, namespace: namespace, hosted_plan: ultimate_plan)

      create(:ci_pipeline, project: project, status: 'pending')
      create(:ci_pipeline, project: project, status: 'running')
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

      expect(pipeline.activity_limit_exceeded?).to be true
    end

    it 'logs the error' do
      expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
        instance_of(Gitlab::Ci::Limit::LimitExceededError),
        project_id: project.id, plan: namespace.actual_plan_name
      )

      subject
    end
  end

  context 'when pipeline activity limit is not exceeded' do
    before do
      ultimate_plan = create(:ultimate_plan)
      create(:plan_limits, plan: ultimate_plan, ci_active_pipelines: 100)
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
  end
end
