# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UpdateOrchestrationPolicyConfiguration do
  let_it_be(:configuration, refind: true) { create(:security_orchestration_policy_configuration, configured_at: nil) }
  let!(:schedule) do
    create(:security_orchestration_policy_rule_schedule, security_orchestration_policy_configuration: configuration)
  end

  let_it_be(:namespace) { create(:namespace) }

  before do
    allow_next_instance_of(Repository) do |repository|
      allow(repository).to receive(:blob_data_at).and_return(active_policies.to_yaml)
      allow(repository).to receive(:last_commit_for_path)
    end
  end

  let(:worker) do
    Class.new do
      def self.name
        'DummyPolicyConfigurationWorker'
      end

      include UpdateOrchestrationPolicyConfiguration
    end.new
  end

  describe '.update_policy_configuration' do
    subject { worker.update_policy_configuration(configuration) }

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
          ]
        }
      end

      it 'executes process services for all policies' do
        active_policies[:scan_execution_policy].each_with_index do |policy, policy_index|
          expect_next_instance_of(Security::SecurityOrchestrationPolicies::ProcessRuleService,
                                  policy_configuration: configuration,
                                  policy_index: policy_index, policy: policy) do |service|
            expect(service).to receive(:execute)
          end
        end

        expect_next_instance_of(Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesService,
          configuration) do |service|
          expect(service).to receive(:execute)
        end

        freeze_time do
          expect(configuration.configured_at).to be_nil
          expect { subject }.not_to change(Security::OrchestrationPolicyRuleSchedule, :count)
          expect(configuration.reload.configured_at).to be_like_time(Time.current)
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
        expect(Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesService).not_to receive(:new)

        expect { subject }.to change(Security::OrchestrationPolicyRuleSchedule, :count).by(-1)
        expect(configuration.reload.configured_at).to be_like_time(Time.current)
      end
    end
  end
end
