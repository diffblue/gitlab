# frozen_string_literal: true

module Security
  class OrchestrationPolicyRuleScheduleNamespaceWorker
    include ApplicationWorker

    feature_category :security_policy_management

    data_consistency :sticky

    idempotent!

    def perform(rule_schedule_id)
      schedule = Security::OrchestrationPolicyRuleSchedule.find_by_id(rule_schedule_id)
      return unless schedule

      security_orchestration_policy_configuration = schedule.security_orchestration_policy_configuration
      return if !security_orchestration_policy_configuration.namespace? || security_orchestration_policy_configuration.namespace.blank?
      return if schedule.next_run_at.future?

      schedule.schedule_next_run!

      security_orchestration_policy_configuration.namespace.all_projects.find_in_batches.each do |projects|
        projects.each do |project|
          with_context(project: project, user: schedule.owner) do
            Security::SecurityOrchestrationPolicies::RuleScheduleService
              .new(container: project, current_user: schedule.owner)
              .execute(schedule)
          end
        end
      end
    end
  end
end
