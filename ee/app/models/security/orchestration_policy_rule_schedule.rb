# frozen_string_literal: true

module Security
  class OrchestrationPolicyRuleSchedule < ApplicationRecord
    include CronSchedulable

    self.table_name = 'security_orchestration_policy_rule_schedules'

    belongs_to :owner, class_name: 'User', foreign_key: 'user_id'
    belongs_to :security_orchestration_policy_configuration,
               class_name: 'Security::OrchestrationPolicyConfiguration',
               foreign_key: 'security_orchestration_policy_configuration_id'

    validates :owner, presence: true
    validates :security_orchestration_policy_configuration, presence: true
    validates :cron, presence: true
    validates :policy_index, presence: true
    validates :rule_index, presence: true

    scope :runnable_schedules, -> { where("next_run_at < ?", Time.zone.now) }
    scope :with_owner, -> { includes(:owner) }
    scope :with_configuration_and_project, -> do
      includes(
        security_orchestration_policy_configuration: [:project, :security_policy_management_project]
      )
    end

    def policy
      security_orchestration_policy_configuration.active_policies.at(policy_index)
    end

    private

    def cron_timezone
      Time.zone.name
    end

    def worker_cron_expression
      Settings.cron_jobs['security_orchestration_policy_rule_schedule_worker']['cron']
    end
  end
end
