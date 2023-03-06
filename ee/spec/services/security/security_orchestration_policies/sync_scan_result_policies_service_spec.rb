# frozen_string_literal: true

require "spec_helper"

RSpec.describe Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesService,
               feature_category: :security_policy_management do
  let_it_be(:configuration, refind: true) { create(:security_orchestration_policy_configuration, configured_at: nil) }

  describe '#execute' do
    subject { described_class.new(configuration).execute }

    it 'triggers worker for the configuration' do
      expect_next_instance_of(
        Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesProjectService,
        configuration
      ) do |sync_service|
        expect(sync_service).to receive(:execute).with(configuration.project_id)
      end

      subject
    end

    context 'with namespace association' do
      let_it_be(:namespace) { create(:namespace) }
      let_it_be(:project) { create(:project, namespace: namespace) }
      let_it_be(:configuration, refind: true) do
        create(:security_orchestration_policy_configuration, configured_at: nil, project: nil, namespace: namespace)
      end

      it 'triggers SyncScanResultPoliciesProjectService for the configuration and project_id' do
        expect_next_instance_of(
          Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesProjectService,
          configuration
        ) do |sync_service|
          expect(sync_service).to receive(:execute).with(project.id)
        end

        subject
      end
    end
  end
end
