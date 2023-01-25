# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ProcessScanResultPolicyWorker do
  let_it_be(:configuration, refind: true) { create(:security_orchestration_policy_configuration, configured_at: nil) }

  let(:active_policies) do
    {
      scan_execution_policy: [],
      scan_result_policy:
      [
        {
          name: 'CS critical policy',
          description: 'This policy with CS for critical policy',
          enabled: true,
          rules: [
            { type: 'scan_finding', branches: %w[production], vulnerabilities_allowed: 0,
              severity_levels: %w[critical], scanners: %w[container_scanning],
              vulnerability_states: %w[newly_detected] }
          ],
          actions: [
            { type: 'require_approval', approvals_required: 1, user_approvers: %w[admin] }
          ]
        }
      ]
    }
  end

  before do
    allow_next_instance_of(Repository) do |repository|
      allow(repository).to receive(:blob_data_at).and_return(active_policies.to_yaml)
      allow(repository).to receive(:last_commit_for_path)
    end
  end

  describe '#perform' do
    subject(:worker) { described_class.new }

    it 'calls three services to general merge request approval rules from the policy YAML' do
      active_policies[:scan_result_policy].each_with_index do |policy, policy_index|
        expect_next_instance_of(Security::SecurityOrchestrationPolicies::ProcessScanResultPolicyService,
                                project: configuration.project,
                                policy_configuration: configuration,
                                policy: policy, policy_index: policy_index) do |service|
          expect(service).to receive(:execute)
        end
        expect_next_instance_of(Security::SecurityOrchestrationPolicies::SyncOpenedMergeRequestsService,
                                project: configuration.project) do |service|
          expect(service).to receive(:execute)
        end
        expect_next_instance_of(Security::SecurityOrchestrationPolicies::SyncOpenMergeRequestsHeadPipelineService,
                                project: configuration.project) do |service|
          expect(service).to receive(:execute)
        end
      end

      worker.perform(configuration.project_id, configuration.id)
    end

    context 'with non existing project' do
      it 'returns prior to triggering any service' do
        expect(Security::SecurityOrchestrationPolicies::ProcessScanResultPolicyService).not_to receive(:execute)
        expect(Security::SecurityOrchestrationPolicies::SyncOpenedMergeRequestsService).not_to receive(:execute)
        expect(Security::SecurityOrchestrationPolicies::SyncOpenMergeRequestsHeadPipelineService)
          .not_to receive(:execute)

        worker.perform('invalid_id', configuration.id)
      end
    end

    context 'with non existing configuration' do
      it 'returns prior to triggering any service' do
        expect(Security::SecurityOrchestrationPolicies::ProcessScanResultPolicyService).not_to receive(:execute)
        expect(Security::SecurityOrchestrationPolicies::SyncOpenedMergeRequestsService).not_to receive(:execute)
        expect(Security::SecurityOrchestrationPolicies::SyncOpenMergeRequestsHeadPipelineService)
          .not_to receive(:execute)

        worker.perform(configuration.project_id, 'invalid_id')
      end
    end

    describe "lease acquisition" do
      let(:lease_key) { described_class.lease_key(configuration.project, configuration) }

      subject { worker.perform(configuration.project_id, configuration.id) }

      it "obtains a #{described_class::LEASE_TTL} second exclusive lease" do
        expect(Gitlab::ExclusiveLeaseHelpers::SleepingLock)
          .to receive(:new)
                .with(lease_key, hash_including(timeout: described_class::LEASE_TTL))
                .and_call_original

        subject
      end

      context 'when lease is not obtained' do
        before do
          Gitlab::ExclusiveLease.new(lease_key, timeout: described_class::LEASE_TTL).try_obtain
        end

        it 'does not invoke Security::SecurityOrchestrationPolicies::SyncOpenedMergeRequestsService' do
          allow_next_instance_of(Security::SecurityOrchestrationPolicies::SyncOpenedMergeRequestsService) do |service|
            expect(service).not_to receive(:execute)
          end

          expect { subject }.to raise_error(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
        end
      end
    end
  end
end
