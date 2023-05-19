# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanResultPolicies::SyncOpenedMergeRequestsWorker, feature_category: :security_policy_management do
  let!(:configuration) { create(:security_orchestration_policy_configuration, configured_at: nil) }

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

  describe '#perform' do
    subject(:worker) { described_class.new }

    it 'calls sync opened mr service for general merge request approval rules from the policy YAML' do
      active_policies[:scan_result_policy].each do
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

    context 'with non existing project' do
      it 'returns prior to triggering service' do
        expect(Security::SecurityOrchestrationPolicies::SyncOpenedMergeRequestsService).not_to receive(:execute)

        worker.perform(non_existing_record_id, configuration.id)
      end
    end

    context 'with non existing configuration' do
      it 'returns prior to triggering any service' do
        expect(Security::SecurityOrchestrationPolicies::SyncOpenedMergeRequestsService).not_to receive(:execute)

        worker.perform(configuration.project_id, non_existing_record_id)
      end
    end

    context 'when no scan result policies are configured' do
      before do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:blob_data_at).and_return([].to_yaml)
        end
      end

      it 'returns prior to triggering service' do
        expect(Security::SecurityOrchestrationPolicies::SyncOpenedMergeRequestsService).not_to receive(:execute)

        worker.perform(configuration.project_id, non_existing_record_id)
      end
    end
  end
end
