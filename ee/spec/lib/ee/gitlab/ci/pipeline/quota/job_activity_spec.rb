# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Gitlab::Ci::Pipeline::Quota::JobActivity, :saas do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:project, reload: true) { create(:project, namespace: namespace) }
  let_it_be(:ultimate_plan, reload: true) { create(:ultimate_plan) }
  let_it_be(:plan_limits, reload: true) { create(:plan_limits, plan: ultimate_plan) }

  let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: ultimate_plan) }

  subject { described_class.new(namespace, project) }

  describe '#enabled?' do
    context 'when limit is enabled in plan' do
      before do
        plan_limits.update!(ci_active_jobs: 10)
      end

      it 'is enabled' do
        expect(subject).to be_enabled
      end
    end

    context 'when limit is not enabled' do
      before do
        plan_limits.update!(ci_active_jobs: 0)
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
    before do
      plan_limits.update!(ci_active_jobs: 2)
    end

    context 'when pipelines created recently' do
      context 'and pipelines are running' do
        let(:pipeline1) { create(:ci_pipeline, project: project, status: 'created', created_at: Time.now) }
        let(:pipeline2) { create(:ci_pipeline, project: project, status: 'created', created_at: Time.now) }

        before do
          create(:ci_build, pipeline: pipeline1)
          create(:ci_build, pipeline: pipeline2)
        end

        context 'when count of jobs in alive pipelines is below the limit' do
          it 'is not exceeded' do
            expect(subject).not_to be_exceeded
          end
        end

        context 'when count of jobs in alive pipelines is above the limit' do
          before do
            create(:ci_build, pipeline: pipeline2)
          end

          it 'is exceeded' do
            expect(subject).to be_exceeded
          end
        end
      end

      context 'and pipelines are completed' do
        before do
          create(:ci_pipeline, project: project, status: 'success', created_at: Time.now).tap do |pipeline|
            create(:ci_build, pipeline: pipeline)
            create(:ci_build, pipeline: pipeline)
            create(:ci_build, pipeline: pipeline)
          end
        end

        it 'is not exceeded' do
          expect(subject).not_to be_exceeded
        end
      end
    end

    context 'when pipelines are older than 24 hours' do
      before do
        create(:ci_pipeline, project: project, status: 'created', created_at: 25.hours.ago).tap do |pipeline|
          create(:ci_build, pipeline: pipeline)
          create(:ci_build, pipeline: pipeline)
          create(:ci_build, pipeline: pipeline)
        end
      end

      it 'is not exceeded' do
        expect(subject).not_to be_exceeded
      end
    end
  end

  describe '#message' do
    context 'when limit is exceeded' do
      before do
        plan_limits.update!(ci_active_jobs: 1)

        create(:ci_pipeline, project: project, status: 'created', created_at: Time.now).tap do |pipeline|
          create(:ci_build, pipeline: pipeline)
          create(:ci_build, pipeline: pipeline)
          create(:ci_build, pipeline: pipeline)
        end
      end

      it 'returns info about pipeline activity limit exceeded' do
        expect(subject.message)
          .to eq "Project has too many active jobs created in the last 24 hours! There are 3 active jobs, but the limit is 1."
      end
    end
  end
end
