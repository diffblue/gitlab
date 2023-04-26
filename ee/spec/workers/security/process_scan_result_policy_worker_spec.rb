# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ProcessScanResultPolicyWorker, feature_category: :security_policy_management do
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

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [configuration.project.id, configuration.id] }
  end

  before do
    allow_next_instance_of(Repository) do |repository|
      allow(repository).to receive(:blob_data_at).and_return(active_policies.to_yaml)
      allow(repository).to receive(:last_commit_for_path)
    end
  end

  describe '#perform' do
    subject(:worker) { described_class.new }

    it 'calls two services to general merge request approval rules from the policy YAML' do
      active_policies[:scan_result_policy].each_with_index do |policy, policy_index|
        expect_next_instance_of(
          Security::SecurityOrchestrationPolicies::ProcessScanResultPolicyService,
          project: configuration.project,
          policy_configuration: configuration,
          policy: policy,
          policy_index: policy_index
        ) do |service|
          expect(service).to receive(:execute)
        end
        expect_next_instance_of(
          Security::SecurityOrchestrationPolicies::SyncOpenedMergeRequestsService,
          project: configuration.project,
          policy_configuration: configuration
        ) do |service|
          expect(service).to receive(:execute)
        end
      end

      worker.perform(configuration.project_id, configuration.id)
    end

    context 'with transaction' do
      context 'when remove_scan_result_policy_transaction is disabled' do
        before do
          stub_feature_flags(remove_scan_result_policy_transaction: false)
        end

        it 'wraps the execution within transaction' do
          expect(Security::OrchestrationPolicyConfiguration).to receive(:transaction).and_yield

          worker.perform(configuration.project_id, configuration.id)
        end
      end

      context 'when remove_scan_result_policy_transaction is enabled' do
        it 'does not wrap the execution within transaction' do
          expect(Security::OrchestrationPolicyConfiguration).not_to receive(:transaction).and_yield

          worker.perform(configuration.project_id, configuration.id)
        end
      end
    end

    shared_context 'with scan_result_policy_reads' do
      let(:scan_result_policy_read) do
        create(:scan_result_policy_read, security_orchestration_policy_configuration: configuration)
      end

      let!(:software_license_without_scan_result_policy) do
        create(:software_license_policy, project: project)
      end

      let!(:software_license_with_scan_result_policy) do
        create(:software_license_policy, project: project,
          scan_result_policy_read: scan_result_policy_read)
      end

      it 'deletes software_license_policies associated to the project' do
        worker.perform(project.id, configuration.id)

        software_license_policies = SoftwareLicensePolicy.where(project_id: project.id)
        expect(software_license_policies).to match_array([software_license_without_scan_result_policy])
      end

      it 'does not delete scan_result_policy_reads' do
        worker.perform(project.id, configuration.id)

        expect(scan_result_policy_read.reload.id).to eq(scan_result_policy_read.id)
      end
    end

    context 'when policy is linked to a project level' do
      let_it_be(:project) { configuration.project }

      include_context 'with scan_result_policy_reads'
    end

    context 'when policy is linked to a group level' do
      let_it_be(:project) { create(:project) }
      let_it_be(:configuration) do
        create(:security_orchestration_policy_configuration,
          namespace: project.namespace,
          project: nil,
          configured_at: nil
        )
      end

      include_context 'with scan_result_policy_reads'
    end

    context 'with non existing project' do
      it 'returns prior to triggering any service' do
        expect(Security::SecurityOrchestrationPolicies::ProcessScanResultPolicyService).not_to receive(:execute)
        expect(Security::SecurityOrchestrationPolicies::SyncOpenedMergeRequestsService).not_to receive(:execute)

        worker.perform('invalid_id', configuration.id)
      end
    end

    context 'with non existing configuration' do
      it 'returns prior to triggering any service' do
        expect(Security::SecurityOrchestrationPolicies::ProcessScanResultPolicyService).not_to receive(:execute)
        expect(Security::SecurityOrchestrationPolicies::SyncOpenedMergeRequestsService).not_to receive(:execute)

        worker.perform(configuration.project_id, 'invalid_id')
      end
    end

    context 'when no scan result policies are configured' do
      before do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:blob_data_at).and_return([].to_yaml)
        end
      end

      it 'returns prior to triggering any service' do
        expect(Security::SecurityOrchestrationPolicies::ProcessScanResultPolicyService).not_to receive(:execute)
        expect(Security::SecurityOrchestrationPolicies::SyncOpenedMergeRequestsService).not_to receive(:execute)

        worker.perform(configuration.project_id, 'invalid_id')
      end
    end
  end
end
