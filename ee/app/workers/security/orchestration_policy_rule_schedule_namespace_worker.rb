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

      security_orchestration_policy_configuration.namespace.all_projects.not_aimed_for_deletion.find_in_batches.each do |projects|
        projects.each do |project|
          user = project.security_policy_bot
          next prepare_security_policy_bot_user(project) unless user

          with_context(project: project, user: user) do
            Security::ScanExecutionPolicies::RuleScheduleWorker.perform_async(project.id, user.id, schedule.id)
          end
        end
      end
    end

    def prepare_security_policy_bot_user(project)
      Security::OrchestrationConfigurationCreateBotWorker.perform_async(project.id, nil)
    end
  end
end
