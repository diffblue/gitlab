# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::ProcessRuleService do
  describe '#execute' do
    let_it_be(:policy_configuration) { create(:security_orchestration_policy_configuration) }
    let_it_be(:owner) { create(:user) }
    let_it_be(:schedule) do
      travel_to(1.day.ago) do
        create(:security_orchestration_policy_rule_schedule, security_orchestration_policy_configuration: policy_configuration)
      end
    end

    let(:policy) do
      {
        name: 'DAST Scan',
        description: 'This policy runs DAST on pipeline and for every 15 mins',
        enabled: true,
        rules: [
          { type: 'pipeline', branches: %w[production] },
          { type: 'schedule', branches: %w[production], cadence: '*/15 * * * *' }
        ],
        actions: [
          { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' }
        ]
      }
    end

    subject(:service) { described_class.new(policy_configuration: policy_configuration, policy_index: 0, policy: policy) }

    before do
      allow(policy_configuration).to receive(:policy_last_updated_by).and_return(owner)
    end

    context 'when security_orchestration_policies_configuration feature is enabled and policy is scheduled' do
      it 'creates new schedule' do
        service.execute

        new_schedule = Security::OrchestrationPolicyRuleSchedule.first
        expect(policy_configuration.configured_at).not_to be_nil
        expect(Security::OrchestrationPolicyRuleSchedule.count).to eq(1)
        expect(new_schedule.id).not_to eq(schedule.id)
        expect(new_schedule.rule_index).to eq(1)
        expect(new_schedule.next_run_at).to be > schedule.next_run_at
      end
    end

    context 'when security_orchestration_policies_configuration feature is disabled' do
      before do
        stub_feature_flags(security_orchestration_policies_configuration: false)
      end

      it 'deletes schedules' do
        expect { service.execute }.to change(Security::OrchestrationPolicyRuleSchedule, :count).by(-1)
        expect(policy_configuration.configured_at).not_to be_nil
      end
    end

    context 'when policy is not of type scheduled' do
      let(:policy) do
        {
          name: 'Run DAST in every pipeline',
          description: 'This policy enforces to run DAST for every pipeline within the project',
          enabled: false,
          rules: [{ type: 'pipeline', branches: %w[production] }],
          actions: [
            { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' }
          ]
        }
      end

      it 'deletes schedules' do
        expect { service.execute }.to change(Security::OrchestrationPolicyRuleSchedule, :count).by(-1)
        expect(policy_configuration.configured_at).not_to be_nil
      end
    end
  end
end
