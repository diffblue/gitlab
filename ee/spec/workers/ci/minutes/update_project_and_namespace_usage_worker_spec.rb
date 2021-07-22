# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::UpdateProjectAndNamespaceUsageWorker do
  let_it_be(:project) { create(:project) }
  let_it_be(:namespace) { project.namespace }

  let(:consumption) { 100 }
  let(:consumption_seconds) { consumption * 60 }
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'executes UpdateProjectAndNamespaceUsageService' do
      service_instance = double
      expect(::Ci::Minutes::UpdateProjectAndNamespaceUsageService).to receive(:new).with(project.id, namespace.id).and_return(service_instance)
      expect(service_instance).to receive(:execute).with(consumption)

      worker.perform(consumption, project.id, namespace.id)
    end

    it 'updates statistics and usage' do
      worker.perform(consumption, project.id, namespace.id)

      expect(project.statistics.reload.shared_runners_seconds).to eq(consumption_seconds)
      expect(namespace.namespace_statistics.reload.shared_runners_seconds).to eq(consumption_seconds)
      expect(Ci::Minutes::NamespaceMonthlyUsage.find_by(namespace: namespace).amount_used).to eq(consumption)
      expect(Ci::Minutes::ProjectMonthlyUsage.find_by(project: project).amount_used).to eq(consumption)
    end

    it 'accumulates only legacy statistics on failure (behaves transactionally)' do
      allow(Ci::Minutes::ProjectMonthlyUsage).to receive(:new).and_raise(StandardError)

      expect { worker.perform(consumption, project.id, namespace.id) }.to raise_error(StandardError)

      expect(project.reload.statistics.shared_runners_seconds).to eq(consumption_seconds)
      expect(namespace.reload.namespace_statistics.shared_runners_seconds).to eq(consumption_seconds)
      expect(Ci::Minutes::NamespaceMonthlyUsage.find_by(namespace: namespace)).to eq(nil)
      expect(Ci::Minutes::ProjectMonthlyUsage.find_by(project: project)).to eq(nil)
      expect(::Ci::Minutes::EmailNotificationService).not_to receive(:new)
    end
  end
end
