# frozen_string_literal: true

module Security
  class OrchestrationPolicyRuleScheduleWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always
    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    feature_category :security_orchestration

    def perform
      Security::OrchestrationPolicyRuleSchedule.with_configuration_and_project.with_owner.runnable_schedules.find_in_batches do |schedules|
        schedules.each do |schedule|
          with_context(project: schedule.security_orchestration_policy_configuration.project, user: schedule.owner) do
            Security::SecurityOrchestrationPolicies::RuleScheduleService
              .new(container: schedule.security_orchestration_policy_configuration.project, current_user: schedule.owner)
              .execute(schedule)
          end
        end
      end
    end
  end
end
