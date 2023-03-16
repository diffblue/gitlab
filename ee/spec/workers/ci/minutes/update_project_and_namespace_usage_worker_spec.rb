# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::UpdateProjectAndNamespaceUsageWorker, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:namespace) { project.namespace }
  let_it_be(:build) { create(:ci_build, project: project) }

  let(:consumption) { 100 }
  let(:consumption_seconds) { consumption * 60 }
  let(:duration) { 60_000 }
  let(:worker) { described_class.new }

  describe '#perform', :clean_gitlab_redis_shared_state do
    context 'when duration param is not passed in' do
      subject { perform_multiple([consumption, project.id, namespace.id, build.id]) }

      context 'behaves idempotently for monthly usage update' do
        it 'executes UpdateProjectAndNamespaceUsageService' do
          service_instance = double
          expect(::Ci::Minutes::UpdateProjectAndNamespaceUsageService).to receive(:new).at_least(:once).and_return(service_instance)
          expect(service_instance).to receive(:execute).at_least(:once).with(consumption, 0)

          subject
        end

        it 'updates monthly usage but not shared_runners_duration', :aggregate_failures do
          subject

          namespace_usage = Ci::Minutes::NamespaceMonthlyUsage.find_by(namespace: namespace)
          expect(namespace_usage.amount_used).to eq(consumption)
          expect(namespace_usage.shared_runners_duration).to eq(0)

          project_usage = Ci::Minutes::ProjectMonthlyUsage.find_by(project: project)
          expect(project_usage.amount_used).to eq(consumption)
          expect(project_usage.shared_runners_duration).to eq(0)
        end
      end

      it 'does not behave idempotently for legacy statistics update', :aggregate_failures do
        expect(::Ci::Minutes::UpdateProjectAndNamespaceUsageService).to receive(:new).twice.and_call_original

        subject

        expect(project.statistics.reload.shared_runners_seconds).to eq(2 * consumption_seconds)
        expect(namespace.reload.namespace_statistics.shared_runners_seconds).to eq(2 * consumption_seconds)
      end
    end

    context 'when duration param is passed in' do
      subject { perform_multiple([consumption, project.id, namespace.id, build.id, { 'duration' => duration }]) }

      context 'behaves idempotently for monthly usage update' do
        it 'executes UpdateProjectAndNamespaceUsageService' do
          service_instance = double
          expect(::Ci::Minutes::UpdateProjectAndNamespaceUsageService).to receive(:new).at_least(:once).and_return(service_instance)
          expect(service_instance).to receive(:execute).at_least(:once).with(consumption, duration)

          subject
        end

        it 'updates monthly usage and shared_runners_duration', :aggregate_failures do
          subject

          namespace_usage = Ci::Minutes::NamespaceMonthlyUsage.find_by(namespace: namespace)
          expect(namespace_usage.amount_used).to eq(consumption)
          expect(namespace_usage.shared_runners_duration).to eq(duration)

          project_usage = Ci::Minutes::ProjectMonthlyUsage.find_by(project: project)
          expect(project_usage.amount_used).to eq(consumption)
          expect(project_usage.shared_runners_duration).to eq(duration)
        end
      end

      it 'does not behave idempotently for legacy statistics update', :aggregate_failures do
        expect(::Ci::Minutes::UpdateProjectAndNamespaceUsageService).to receive(:new).twice.and_call_original

        subject

        expect(project.statistics.reload.shared_runners_seconds).to eq(2 * consumption_seconds)
        expect(namespace.reload.namespace_statistics.shared_runners_seconds).to eq(2 * consumption_seconds)
      end
    end
  end
end
