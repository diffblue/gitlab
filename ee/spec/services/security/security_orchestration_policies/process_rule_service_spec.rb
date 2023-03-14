# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::ProcessRuleService, feature_category: :security_policy_management do
  describe '#execute' do
    let_it_be(:plan_limits) { create(:plan_limits, :default_plan, security_policy_scan_execution_schedules: 1) }
    let_it_be(:policy_configuration) { create(:security_orchestration_policy_configuration) }
    let_it_be(:owner) { create(:user) }

    let(:policy) do
      rules = [
        { type: 'pipeline', branches: %w[production] },
        { type: 'schedule', branches: %w[production], cadence: '*/15 * * * *' }
      ]

      build(:scan_execution_policy, rules: rules)
    end

    subject(:service) { described_class.new(policy_configuration: policy_configuration, policy_index: 0, policy: policy) }

    before do
      allow(policy_configuration).to receive(:policy_last_updated_by).and_return(owner)
    end

    context 'when security_orchestration_policies_configuration policy is scheduled' do
      it 'creates new schedule' do
        service.execute

        expect(Security::OrchestrationPolicyRuleSchedule.count).to eq(1)
        schedule = Security::OrchestrationPolicyRuleSchedule.last
        expect(schedule.security_orchestration_policy_configuration).to eq(policy_configuration)
        expect(schedule.policy_index).to eq(0)
        expect(schedule.rule_index).to eq(1)
        expect(schedule.cron).to eq('*/15 * * * *')
        expect(schedule.owner).to eq(owner)
        expect(schedule.next_run_at).to be > Time.current
      end

      context 'when limits are exceeded' do
        let(:policy) do
          rules = [
            { type: 'pipeline', branches: %w[production] },
            { type: 'schedule', branches: %w[production], cadence: '*/15 * * * *' },
            { type: 'schedule', branches: %w[production], cadence: '2 * * * *' },
            { type: 'schedule', branches: %w[production], cadence: '4 * * * *' }
          ]

          build(:scan_execution_policy, rules: rules)
        end

        it 'creates schedules only to a configured limit' do
          service.execute

          expect(Security::OrchestrationPolicyRuleSchedule.count).to eq(1)
        end
      end
    end

    context 'when cadence is not valid' do
      let(:policy) do
        rules = [
          { type: 'pipeline', branches: %w[production] },
          { type: 'schedule', branches: %w[production], cadence: 'invalid cadence' }
        ]

        build(:scan_execution_policy, rules: rules)
      end

      it 'does not create a new schedule' do
        expect { service.execute }.not_to change(Security::OrchestrationPolicyRuleSchedule, :count)
      end
    end

    context 'when cadence is empty' do
      let(:policy) do
        rules = [
          { type: 'pipeline', branches: %w[production] },
          { type: 'schedule', branches: %w[production], cadence: '' }
        ]

        build(:scan_execution_policy, rules: rules)
      end

      it 'does not create a new schedule' do
        expect { service.execute }.not_to change(Security::OrchestrationPolicyRuleSchedule, :count)
      end
    end

    context 'when cadence is missing' do
      let(:policy) do
        rules = [
          { type: 'pipeline', branches: %w[production] },
          { type: 'schedule', branches: %w[production], cadence: nil }
        ]

        build(:scan_execution_policy, rules: rules)
      end

      it 'does not create a new schedule' do
        expect { service.execute }.not_to change(Security::OrchestrationPolicyRuleSchedule, :count)
      end
    end

    context 'when policy is not of type scheduled' do
      let(:policy) { build(:scan_execution_policy) }

      it 'does not create a new schedule' do
        expect { service.execute }.not_to change(Security::OrchestrationPolicyRuleSchedule, :count)
      end
    end
  end
end
