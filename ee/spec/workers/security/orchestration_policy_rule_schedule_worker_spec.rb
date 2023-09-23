# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::OrchestrationPolicyRuleScheduleWorker, feature_category: :security_policy_management do
  describe '#perform' do
    let_it_be(:project) { create(:project) }
    let_it_be(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, project: project) }
    let_it_be(:schedule) { create(:security_orchestration_policy_rule_schedule, security_orchestration_policy_configuration: security_orchestration_policy_configuration) }

    subject(:worker) { described_class.new }

    before do
      allow(Security::OrchestrationConfigurationCreateBotWorker).to receive(:perform_async)
    end

    context 'when schedule exists' do
      before do
        schedule.update_column(:next_run_at, 1.minute.ago)
      end

      context 'when schedule is created for security orchestration policy configuration in project' do
        it 'creates async new policy bot user only when it is missing for the project' do
          expect(Security::OrchestrationConfigurationCreateBotWorker).to receive(:perform_async).with(project.id, nil)
          expect { worker.perform }.not_to change { User.count }
        end

        it 'does not invoke the rule schedule worker when there is no security policy bot' do
          expect(Security::ScanExecutionPolicies::RuleScheduleWorker).not_to receive(:perform_async)

          worker.perform
        end

        it 'does not update next run at value' do
          expect { worker.perform }.not_to change { schedule.reload.next_run_at }
        end

        context 'when project is marked for deletion' do
          before do
            stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)

            security_orchestration_policy_configuration.project.update!(marked_for_deletion_at: Time.zone.now)
          end

          it 'does not invoke the rule schedule worker' do
            expect(Security::ScanExecutionPolicies::RuleScheduleWorker).not_to receive(:perform_async)

            worker.perform
          end
        end
      end

      context 'when policy has a security_policy_bot user' do
        let_it_be(:security_policy_bot) { create(:user, user_type: :security_policy_bot) }
        let_it_be(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration) }
        let_it_be(:schedule) { create(:security_orchestration_policy_rule_schedule, security_orchestration_policy_configuration: security_orchestration_policy_configuration) }

        before do
          security_orchestration_policy_configuration.project.add_guest(security_policy_bot)
        end

        it 'updates next run at value' do
          worker.perform

          expect(schedule.reload.next_run_at).to be > Time.zone.now
        end

        it 'invokes the rule schedule worker with the bot user' do
          expect(Security::ScanExecutionPolicies::RuleScheduleWorker).to receive(:perform_async).with(schedule.security_orchestration_policy_configuration.project.id, security_policy_bot.id, schedule.id)

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

      it 'does not invoke rule schedule worker' do
        expect(Security::ScanExecutionPolicies::RuleScheduleWorker).not_to receive(:perform_async)

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
