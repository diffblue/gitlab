# frozen_string_literal: true

require "spec_helper"

RSpec.describe Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesProjectService,
  feature_category: :security_policy_management do
  let_it_be(:configuration, refind: true) { create(:security_orchestration_policy_configuration, configured_at: nil) }

  describe '#execute' do
    let(:project_id) { 999_999 }

    subject(:execute) { described_class.new(configuration).execute(project_id) }

    it 'triggers worker for the configuration and provided project_id' do
      expect(Security::ProcessScanResultPolicyWorker).to receive(:perform_async).with(project_id,
        configuration.id)

      execute
    end

    context 'with delay' do
      let(:delay) { 1.minute }

      subject(:execute) { described_class.new(configuration).execute(project_id, delay: delay) }

      it 'schedules job for the configuration and provided project_id' do
        expect(Security::ProcessScanResultPolicyWorker).to receive(:perform_in).with(delay,
          project_id, configuration.id)

        execute
      end
    end
  end
end
