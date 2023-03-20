# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UpdateOrchestrationPolicyConfiguration, feature_category: :security_policy_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:configuration, refind: true) do
    create(:security_orchestration_policy_configuration, configured_at: nil, project: project)
  end

  let!(:schedule) do
    create(
      :security_orchestration_policy_rule_schedule,
      security_orchestration_policy_configuration: configuration,
      owner: project.owner
    )
  end

  before do
    allow_next_instance_of(Repository) do |repository|
      allow(repository).to receive(:blob_data_at).and_return(active_policies.to_yaml)
      allow(repository).to receive(:last_commit_for_path)
    end

    allow(configuration).to receive(:policy_last_updated_by).and_return(project.owner)
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

      it 'updates configuration.configured_at to the current time', :freeze_time do
        expect { subject }.to change { configuration.configured_at }.from(nil).to(Time.current)
      end

      it 'executes SyncScanResultPoliciesService' do
        expect_next_instance_of(
          Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesService, configuration
        ) do |service|
          expect(service).to receive(:execute).with(no_args)
        end

        subject
      end

      it 'executes ProcessRuleService for each policy' do
        active_policies[:scan_execution_policy].each_with_index do |policy, policy_index|
          expect_next_instance_of(
            Security::SecurityOrchestrationPolicies::ProcessRuleService,
            policy_configuration: configuration,
            policy_index: policy_index, policy: policy
          ) do |service|
            expect(service).to receive(:execute)
          end
        end

        subject
      end

      shared_examples 'creates new rule schedules' do |expected_schedules:|
        it 'creates a rule schedule for each schedule rule in the scan execution policies' do
          expect { subject }.to change(Security::OrchestrationPolicyRuleSchedule, :count).from(1).to(expected_schedules)
        end

        it 'deletes existing rule schedules', :freeze_time do
          subject

          Security::OrchestrationPolicyRuleSchedule.all.each do |rule_schedule|
            expect(rule_schedule.created_at).to eq(Time.current)
          end
        end
      end

      context 'with one schedule rule per policy' do
        include_examples 'creates new rule schedules', expected_schedules: 2
      end

      context 'with multiple schedule rules per policy' do
        before do
          active_policies[:scan_execution_policy].each do |policy|
            policy[:rules] << { type: 'schedule', branches: %w[staging], cadence: '*/20 * * * *' }
          end
        end

        include_examples 'creates new rule schedules', expected_schedules: 4
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
        expect(Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesProjectService).not_to receive(:new)

        expect { subject }.to change(Security::OrchestrationPolicyRuleSchedule, :count).by(-1)
        expect(configuration.reload.configured_at).to be_like_time(Time.current)
      end
    end
  end
end
