# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::UpdateProjectAndNamespaceUsageWorker do
  let_it_be(:project) { create(:project) }
  let_it_be(:namespace) { project.namespace }
  let_it_be(:build) { create(:ci_build, project: project) }

  let(:consumption) { 100 }
  let(:consumption_seconds) { consumption * 60 }
  let(:worker) { described_class.new }

  describe '#perform' do
    shared_examples 'executes the update' do
      it 'executes UpdateProjectAndNamespaceUsageService' do
        service_instance = double
        expect(::Ci::Minutes::UpdateProjectAndNamespaceUsageService).to receive(:new).at_least(:once).and_return(service_instance)
        expect(service_instance).to receive(:execute).at_least(:once).with(consumption)

        subject
      end

      it 'updates monthly usage' do
        subject

        expect(Ci::Minutes::NamespaceMonthlyUsage.find_by(namespace: namespace).amount_used).to eq(consumption)
        expect(Ci::Minutes::ProjectMonthlyUsage.find_by(project: project).amount_used).to eq(consumption)
      end
    end

    shared_examples 'skips the update' do
      it 'does not execute UpdateProjectAndNamespaceUsageService' do
        expect(::Ci::Minutes::UpdateProjectAndNamespaceUsageService).not_to receive(:new)

        subject
      end
    end

    context 'when build_id is not passed as parameter (param backward compatibility)' do
      subject { worker.perform(consumption, project.id, namespace.id) }

      it_behaves_like 'executes the update'

      it 'updates legacy statistics' do
        subject

        expect(project.statistics.reload.shared_runners_seconds).to eq(consumption_seconds)
        expect(namespace.reload.namespace_statistics.shared_runners_seconds).to eq(consumption_seconds)
      end

      context 'does not behave idempotently' do
        subject { perform_multiple([consumption, project.id, namespace.id], worker: worker) }

        it 'executes the operation multiple times' do
          expect(::Ci::Minutes::UpdateProjectAndNamespaceUsageService).to receive(:new).twice.and_call_original

          subject

          expect(project.statistics.reload.shared_runners_seconds).to eq(2 * consumption_seconds)
          expect(namespace.reload.namespace_statistics.shared_runners_seconds).to eq(2 * consumption_seconds)
          expect(Ci::Minutes::NamespaceMonthlyUsage.find_by(namespace: namespace).amount_used).to eq(2 * consumption)
          expect(Ci::Minutes::ProjectMonthlyUsage.find_by(project: project).amount_used).to eq(2 * consumption)
        end
      end
    end

    context 'when build_id is passed as parameter', :clean_gitlab_redis_shared_state do
      subject { perform_multiple([consumption, project.id, namespace.id, build.id]) }

      context 'behaves idempotently for monthly usage update' do
        it_behaves_like 'executes the update'
      end

      it 'does not behave idempotently for legacy statistics update' do
        expect(::Ci::Minutes::UpdateProjectAndNamespaceUsageService).to receive(:new).twice.and_call_original

        subject

        expect(project.statistics.reload.shared_runners_seconds).to eq(2 * consumption_seconds)
        expect(namespace.reload.namespace_statistics.shared_runners_seconds).to eq(2 * consumption_seconds)
      end
    end
  end
end
