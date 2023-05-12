# frozen_string_literal: true

module Security
  class OrchestrationPolicyRuleScheduleWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always
    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    feature_category :security_policy_management

    def perform
      Security::OrchestrationPolicyRuleSchedule.with_configuration_and_project_or_namespace.with_owner.runnable_schedules.find_in_batches do |schedules|
        schedules.each do |schedule|
          with_context(project: schedule.security_orchestration_policy_configuration.project, user: schedule.owner) do
            if schedule.security_orchestration_policy_configuration.project?
              schedule_rules(schedule)
            else
              Security::OrchestrationPolicyRuleScheduleNamespaceWorker.perform_async(schedule.id)
            end
          end
        end
      end
    end

    private

    def schedule_rules(schedule)
      schedule.schedule_next_run!

      user = schedule.security_orchestration_policy_configuration.bot_user || schedule.owner

      Security::SecurityOrchestrationPolicies::RuleScheduleService
        .new(container: schedule.security_orchestration_policy_configuration.project, current_user: user)
        .execute(schedule)
    end
  end
end
