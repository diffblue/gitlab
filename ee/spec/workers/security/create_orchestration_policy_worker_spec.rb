# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::CreateOrchestrationPolicyWorker do
  describe '#perform' do
    let_it_be(:configuration) { create(:security_orchestration_policy_configuration, configured_at: nil) }
    let_it_be(:schedule) { create(:security_orchestration_policy_rule_schedule, security_orchestration_policy_configuration: configuration) }

    before do
      allow_next_instance_of(Repository) do |repository|
        allow(repository).to receive(:blob_data_at).and_return(active_policies.to_yaml)
        allow(repository).to receive(:last_commit_for_path)
      end
    end

    subject(:worker) { described_class.new }

    context 'when policy is valid' do
      let(:active_policies) do
        {
          scan_execution_policy:
          [
            {
              name: 'Scheduled DAST 1',
              description: 'This policy runs DAST for every 20 mins',
              enabled: true,
              rules: [{ type: 'schedule', branches: %w[production], cadence: '*/20 * * * *' }],
              actions: [
                { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' }
              ]
            },
            {
              name: 'Scheduled DAST 2',
              description: 'This policy runs DAST for every 20 mins',
              enabled: true,
              rules: [{ type: 'schedule', branches: %w[production], cadence: '*/20 * * * *' }],
              actions: [
                { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' }
              ]
            }
          ],
          scan_result_policy:
          [
            {
              name: 'CS critical policy',
              description: 'This policy with CS for critical policy',
              enabled: true,
              rules: [{ type: 'scan_finding', branches: %w[production], vulnerabilities_allowed: 0, severity_levels: %w[critical], scanners: %w[container_scanning], vulnerability_states: %w[newly_detected] }],
              actions: [
                { type: 'require_approval', approvals_required: 1, user_approvers: %w[admin] }
              ]
            }
          ]
        }
      end

      it 'executes process services for all policies' do
        active_policies[:scan_execution_policy].each_with_index do |policy, policy_index|
          expect_next_instance_of(Security::SecurityOrchestrationPolicies::ProcessRuleService,
                                  policy_configuration: configuration, policy_index: policy_index, policy: policy) do |service|
            expect(service).to receive(:execute)
          end
        end

        active_policies[:scan_result_policy].each_with_index do |policy, policy_index|
          expect_next_instance_of(Security::SecurityOrchestrationPolicies::ProcessScanResultPolicyService,
                                  policy_configuration: configuration, policy: policy, policy_index: policy_index) do |service|
            expect(service).to receive(:execute)
          end
        end

        expect(configuration.configured_at).to be_nil
        expect { worker.perform }.not_to change(Security::OrchestrationPolicyRuleSchedule, :count)
        expect(configuration.reload.configured_at).not_to be_nil
      end

      context 'with existing project approval rules' do
        let!(:approval_rule) { create(:approval_project_rule, :scan_finding, project: configuration.project )}

        before do
          allow_next_instance_of(Security::SecurityOrchestrationPolicies::ProcessRuleService) do |rule_service|
            allow(rule_service).to receive(:execute)
          end
          allow_next_instance_of(Security::SecurityOrchestrationPolicies::ProcessScanResultPolicyService) do |rule_service|
            allow(rule_service).to receive(:execute)
          end
        end

        it 'deletes all approval_rules' do
          expect { worker.perform }.to change(configuration.approval_rules, :count).by(-1)
        end
      end
    end

    context 'when policy is invalid' do
      let(:active_policies) do
        {
          scan_execution_policy:
          [
            {
              key: 'invalid',
              label: 'invalid'
            }
          ]
        }
      end

      it 'does not execute process for any policy' do
        expect(Security::SecurityOrchestrationPolicies::ProcessRuleService).not_to receive(:new)
        expect(Security::SecurityOrchestrationPolicies::ProcessScanResultPolicyService).not_to receive(:new)

        expect { worker.perform }.to change(Security::OrchestrationPolicyRuleSchedule, :count).by(-1)
        expect(configuration.reload.configured_at).to be_nil
      end

      context 'with existing project approval rules' do
        let!(:approval_rule) { create(:approval_project_rule, :scan_finding, project: configuration.project )}

        before do
          allow_next_instance_of(Security::SecurityOrchestrationPolicies::ProcessRuleService) do |rule_service|
            allow(rule_service).to receive(:execute)
          end
          allow_next_instance_of(Security::SecurityOrchestrationPolicies::ProcessScanResultPolicyService) do |rule_service|
            allow(rule_service).to receive(:execute)
          end
        end

        it 'does not delete the existing approval_rules' do
          expect { worker.perform }.not_to change(configuration.approval_rules, :count)
        end
      end
    end
  end
end
