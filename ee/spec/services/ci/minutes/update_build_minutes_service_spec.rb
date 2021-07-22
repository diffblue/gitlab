# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::UpdateBuildMinutesService do
  let(:namespace) { create(:namespace, shared_runners_minutes_limit: 100) }
  let(:project) { create(:project, :private, namespace: namespace) }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  let(:build) do
    create(:ci_build, :success,
      runner: runner, pipeline: pipeline,
      started_at: 2.hours.ago, finished_at: 1.hour.ago)
  end

  let(:namespace_amount_used) { Ci::Minutes::NamespaceMonthlyUsage.find_or_create_current(namespace_id: namespace.id).amount_used }
  let(:project_amount_used) { Ci::Minutes::ProjectMonthlyUsage.find_or_create_current(project_id: project.id).amount_used }

  subject { described_class.new(project, nil).execute(build) }

  shared_examples 'executes service' do
    shared_examples 'new tracking matches legacy tracking' do
      it 'stores the same information in both legacy and new tracking' do
        subject

        expect(namespace_amount_used)
          .to eq((namespace.reload.namespace_statistics.shared_runners_seconds.to_f / 60).round(2))

        expect(project_amount_used)
          .to eq((project.statistics.reload.shared_runners_seconds.to_f / 60).round(2))
      end
    end

    shared_examples 'does nothing' do
      it 'does not update legacy statistics' do
        subject

        expect(project.statistics.reload.shared_runners_seconds).to eq(0)
        expect(namespace.namespace_statistics).to be_nil
      end

      it 'does not update namespace monthly usage' do
        expect { subject }.not_to change { Ci::Minutes::NamespaceMonthlyUsage.count }
      end

      it 'does not update project monthly usage' do
        expect { subject }.not_to change { Ci::Minutes::ProjectMonthlyUsage.count }
      end

      it 'does not observe the difference between actual vs live consumption' do
        expect(::Gitlab::Ci::Pipeline::Metrics)
          .not_to receive(:gitlab_ci_difference_live_vs_actual_minutes)

        subject
      end

      it 'does not send an email' do
        allow(Gitlab).to receive(:com?).and_return(true)

        expect(Ci::Minutes::EmailNotificationService).not_to receive(:new)

        subject
      end
    end

    context 'with shared runner' do
      let(:cost_factor) { 2.0 }
      let(:runner) { create(:ci_runner, :instance, private_projects_minutes_cost_factor: cost_factor) }

      it 'creates a statistics and sets duration with applied cost factor' do
        subject

        expect(project.statistics.reload.shared_runners_seconds)
          .to eq(build.duration.to_i * 2)

        expect(namespace.namespace_statistics.reload.shared_runners_seconds)
          .to eq(build.duration.to_i * 2)
      end

      it 'tracks the usage on a monthly basis' do
        subject

        expect(namespace_amount_used).to eq((60 * 2).to_f)
        expect(project_amount_used).to eq((60 * 2).to_f)
      end

      it_behaves_like 'new tracking matches legacy tracking'

      context 'when on .com' do
        before do
          allow(Gitlab).to receive(:com?).and_return(true)
        end

        it 'sends an email' do
          expect_next_instance_of(Ci::Minutes::EmailNotificationService) do |service|
            expect(service).to receive(:execute)
          end

          subject
        end
      end

      context 'when not on .com' do
        before do
          allow(Gitlab).to receive(:com?).and_return(false)
        end

        it 'does not send an email' do
          expect(Ci::Minutes::EmailNotificationService).not_to receive(:new)

          subject
        end
      end

      context 'when feature flag ci_minutes_monthly_tracking is disabled' do
        before do
          stub_feature_flags(ci_minutes_monthly_tracking: false)
        end

        it 'does not track usage on a monthly basis' do
          expect(namespace_amount_used).to eq(0)
          expect(project_amount_used).to eq(0)
        end
      end

      context 'when consumption is 0' do
        let(:build) do
          create(:ci_build, :success,
            runner: runner, pipeline: pipeline,
            started_at: Time.current, finished_at: Time.current)
        end

        it_behaves_like 'does nothing'
      end

      context 'when statistics and usage have existing amounts' do
        let(:usage_in_seconds) { 100 }
        let(:usage_in_minutes) { (100.to_f / 60).round(2) }

        before do
          project.statistics.update!(shared_runners_seconds: usage_in_seconds)
          namespace.create_namespace_statistics(shared_runners_seconds: usage_in_seconds)
          create(:ci_namespace_monthly_usage, namespace: namespace, amount_used: usage_in_minutes)
          create(:ci_project_monthly_usage, project: project, amount_used: usage_in_minutes)
        end

        it 'updates statistics and adds duration with applied cost factor' do
          subject

          expect(project.statistics.reload.shared_runners_seconds)
            .to eq(usage_in_seconds + build.duration.to_i * 2)

          expect(namespace.namespace_statistics.reload.shared_runners_seconds)
            .to eq(usage_in_seconds + build.duration.to_i * 2)
        end

        it 'tracks the usage on a monthly basis' do
          subject

          expect(namespace_amount_used).to eq(usage_in_minutes + 60 * 2)
          expect(project_amount_used).to eq(usage_in_minutes + 60 * 2)
        end

        it_behaves_like 'new tracking matches legacy tracking'

        context 'when feature flag ci_minutes_monthly_tracking is disabled' do
          before do
            stub_feature_flags(ci_minutes_monthly_tracking: false)
          end

          it 'does not track usage on a monthly basis' do
            subject

            expect(namespace_amount_used).to eq(usage_in_minutes)
            expect(project_amount_used).to eq(usage_in_minutes)
          end
        end
      end

      context 'when group is subgroup' do
        let(:root_ancestor) { create(:group, shared_runners_minutes_limit: 100) }
        let(:namespace) { create(:group, parent: root_ancestor) }

        let(:namespace_amount_used) { Ci::Minutes::NamespaceMonthlyUsage.find_or_create_current(namespace_id: root_ancestor.id).amount_used }

        it 'creates a statistics in root group' do
          subject

          expect(root_ancestor.namespace_statistics.reload.shared_runners_seconds)
            .to eq(build.duration.to_i * 2)
        end

        it 'tracks the usage on a monthly basis' do
          subject

          expect(namespace_amount_used).to eq(60 * 2)
          expect(project_amount_used).to eq(60 * 2)
        end

        it 'stores the same information in both legacy and new tracking' do
          subject

          expect(namespace_amount_used)
            .to eq((root_ancestor.namespace_statistics.reload.shared_runners_seconds.to_f / 60).round(2))

          expect(project_amount_used)
            .to eq((project.statistics.reload.shared_runners_seconds.to_f / 60).round(2))
        end
      end

      context 'when live tracking exists for the build', :redis do
        before do
          allow(Gitlab).to receive(:com?).and_return(true)

          build.update!(status: :running)

          freeze_time do
            ::Ci::Minutes::TrackLiveConsumptionService.new(build).tap do |service|
              service.time_last_tracked_consumption!((build.duration.to_i - 5.minutes).ago)
              service.execute
            end
          end

          build.update!(status: :success)
        end

        it 'observes the difference between actual vs live consumption' do
          histogram = double(:histogram)
          expect(::Gitlab::Ci::Pipeline::Metrics)
            .to receive(:gitlab_ci_difference_live_vs_actual_minutes)
            .and_return(histogram)

          expect(histogram).to receive(:observe).with({ plan: 'free' }, 5 * cost_factor)

          subject
        end

        it_behaves_like 'new tracking matches legacy tracking'
      end

      context 'when live tracking does not exist for the build' do
        it 'does not observe the difference' do
          expect(::Gitlab::Ci::Pipeline::Metrics).not_to receive(:gitlab_ci_difference_live_vs_actual_minutes)

          subject
        end
      end
    end

    context 'for specific runner' do
      let(:runner) { create(:ci_runner, :project) }

      it_behaves_like 'does nothing'
    end
  end

  describe '#execute' do
    context 'when cancel_pipelines_prior_to_destroy enabled', :sidekiq_inline do
      include_examples 'executes service'
    end

    context 'when cancel_pipelines_prior_to_destroy disabled' do
      before do
        stub_feature_flags(cancel_pipelines_prior_to_destroy: false)
      end

      include_examples 'executes service'
    end
  end
end
