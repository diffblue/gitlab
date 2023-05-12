# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::OrchestrationPolicyRuleScheduleWorker, feature_category: :security_policy_management do
  describe '#perform' do
    let_it_be(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration) }
    let_it_be(:schedule) { create(:security_orchestration_policy_rule_schedule, security_orchestration_policy_configuration: security_orchestration_policy_configuration) }

    subject(:worker) { described_class.new }

    context 'when schedule exists' do
      before do
        schedule.update_column(:next_run_at, 1.minute.ago)
      end

      context 'when schedule is created for security orchestration policy configuration in project' do
        it 'executes the rule schedule service' do
          expect_next_instance_of(
            Security::SecurityOrchestrationPolicies::RuleScheduleService,
            container: schedule.security_orchestration_policy_configuration.project,
            current_user: schedule.owner
          ) do |service|
            expect(service).to receive(:execute)
          end

          worker.perform
        end

        it 'updates next run at value' do
          worker.perform

          expect(schedule.reload.next_run_at).to be > Time.zone.now
        end
      end

      context 'when policy has a security_policy_bot user' do
        let_it_be(:security_policy_bot) { create(:user, user_type: :security_policy_bot) }
        let_it_be(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, bot_user: security_policy_bot) }
        let_it_be(:schedule) { create(:security_orchestration_policy_rule_schedule, security_orchestration_policy_configuration: security_orchestration_policy_configuration) }

        before do
          security_orchestration_policy_configuration.project.add_guest(security_policy_bot)
        end

        it 'executes the rule schedule service with the bot user' do
          expect_next_instance_of(
            Security::SecurityOrchestrationPolicies::RuleScheduleService,
            container: schedule.security_orchestration_policy_configuration.project,
            current_user: security_policy_bot
          ) do |service|
            expect(service).to receive(:execute)
          end

          worker.perform
        end
      end

      context 'when schedule is created for security orchestration policy configuration in namespace' do
        let_it_be(:namespace) { create(:group) }

        before do
          security_orchestration_policy_configuration.update!(namespace: namespace, project: nil)
        end

        it 'schedules the OrchestrationPolicyRuleScheduleNamespaceWorker for namespace' do
          expect(Security::OrchestrationPolicyRuleScheduleNamespaceWorker).to receive(:perform_async).with(schedule.id)

          worker.perform
        end
      end
    end

    context 'when schedule does not exist' do
      before do
        schedule.update_column(:next_run_at, 1.minute.from_now)
      end

      it 'does not execute the rule schedule service' do
        expect(Security::SecurityOrchestrationPolicies::RuleScheduleService).not_to receive(:new)

        worker.perform
      end
    end

    context 'when multiple schedules exists' do
      before do
        schedule.update_column(:next_run_at, 1.minute.ago)
      end

      def record_preloaded_queries
        recorder = ActiveRecord::QueryRecorder.new { worker.perform }
        recorder.data.values.flat_map { |v| v[:occurrences] }.select do |query|
          ['FROM "projects"', 'FROM "users"', 'FROM "security_orchestration_policy_configurations"'].any? do |s|
            query.include?(s)
          end
        end
      end

      it 'preloads configuration, project and owner to avoid N+1 queries' do
        expected_count = record_preloaded_queries.count

        travel_to(30.minutes.ago) { create_list(:security_orchestration_policy_rule_schedule, 5) }
        actual_count = record_preloaded_queries.count

        expect(actual_count).to eq(expected_count)
      end
    end
  end
end
