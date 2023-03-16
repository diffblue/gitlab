# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::CreateOrchestrationPolicyWorker, feature_category: :security_policy_management do
  describe '#perform' do
    let(:configuration) { create(:security_orchestration_policy_configuration, configured_at: configured_at) }

    subject(:worker) { described_class.new }

    context 'when newly created' do
      let(:configured_at) { nil }

      it 'schedules Security::SyncScanPoliciesWorker job' do
        expect(Security::SyncScanPoliciesWorker).to receive(:perform_async).with(configuration.id)

        worker.perform
      end
    end

    context 'when project has been updated earlier than configuration policy', :freeze_time do
      let(:configured_at) { 10.minutes.from_now }

      before do
        allow(configuration.security_policy_management_project).to receive(:last_repository_updated_at) { Time.current }
      end

      it 'does not schedules Security::SyncScanPoliciesWorker job' do
        expect(Security::SyncScanPoliciesWorker).not_to receive(:perform_async)

        worker.perform
      end
    end
  end
end
