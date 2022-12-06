# frozen_string_literal: true

require "spec_helper"

RSpec.describe Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesService do
  let_it_be(:configuration, refind: true) { create(:security_orchestration_policy_configuration, configured_at: nil) }

  describe '#execute' do
    subject { described_class.new(configuration).execute }

    it 'triggers worker for the configuration' do
      expect(Security::ProcessScanResultPolicyWorker).to receive(:perform_async).with(configuration.project_id,
                                                                                      configuration.id)

      subject
    end

    context 'with namespace association' do
      let_it_be(:namespace) { create(:namespace) }
      let_it_be(:project) { create(:project, namespace: namespace) }
      let_it_be(:configuration, refind: true) do
        create(:security_orchestration_policy_configuration, configured_at: nil, project: nil, namespace: namespace)
      end

      it 'triggers worker for the configuration' do
        expect(Security::ProcessScanResultPolicyWorker).to receive(:perform_async).with(project.id, configuration.id)

        subject
      end
    end
  end
end
