# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::OrchestrationPolicyRuleScheduleNamespaceWorker, feature_category: :security_policy_management do
  describe '#perform' do
    let_it_be(:namespace) { create(:group) }
    let_it_be(:project_1) { create(:project, namespace: namespace) }
    let_it_be(:project_2) { create(:project, namespace: namespace) }
    let_it_be(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, :namespace, namespace: namespace) }
    let_it_be(:schedule) { create(:security_orchestration_policy_rule_schedule, security_orchestration_policy_configuration: security_orchestration_policy_configuration) }

    let(:schedule_id) { schedule.id }
    let(:worker) { described_class.new }

    context 'when schedule exists' do
      context 'when schedule is created for security orchestration policy configuration in namespace' do
        context 'when next_run_at is in future' do
          before do
            schedule.update_column(:next_run_at, 1.minute.from_now)
          end

          it 'does not execute the rule schedule service' do
            expect(Security::SecurityOrchestrationPolicies::RuleScheduleService).not_to receive(:new)

            worker.perform(schedule_id)
          end
        end

        context 'when next_run_at is in the past' do
          before do
            schedule.update_column(:next_run_at, 1.minute.ago)
          end

          it 'executes the rule schedule service for all projects in the group' do
            expect_next_instance_of(
              Security::SecurityOrchestrationPolicies::RuleScheduleService,
              project: project_1,
              current_user: schedule.owner
            ) do |service|
              expect(service).to receive(:execute)
            end

            expect_next_instance_of(
              Security::SecurityOrchestrationPolicies::RuleScheduleService,
              project: project_2,
              current_user: schedule.owner
            ) do |service|
              expect(service).to receive(:execute)
            end

            worker.perform(schedule_id)
          end

          it 'updates next run at value' do
            worker.perform(schedule_id)

            expect(schedule.reload.next_run_at).to be > Time.zone.now
          end

          context 'with namespace including project marked for deletion' do
            let_it_be(:project_pending_deletion) { create(:project, namespace: namespace, marked_for_deletion_at: Time.zone.now) }

            before do
              allow(Security::SecurityOrchestrationPolicies::RuleScheduleService).to receive(:new).and_call_original
            end

            it 'does not call RuleScheduleService for the project' do
              expect(Security::SecurityOrchestrationPolicies::RuleScheduleService).not_to receive(:new).with(project: project_pending_deletion, current_user: anything).and_call_original

              worker.perform(schedule_id)
            end
          end
        end
      end

      context 'when schedule is created for security orchestration policy configuration in project' do
        before do
          security_orchestration_policy_configuration.update!(project: project_1, namespace: nil)
        end

        it 'does not execute the rule schedule service' do
          expect(Security::SecurityOrchestrationPolicies::RuleScheduleService).not_to receive(:new)

          worker.perform(schedule_id)
        end
      end
    end

    context 'when schedule does not exist' do
      let(:schedule_id) { non_existing_record_id }

      it 'does not execute the rule schedule service' do
        expect(Security::SecurityOrchestrationPolicies::RuleScheduleService).not_to receive(:new)

        worker.perform(schedule_id)
      end
    end
  end
end
