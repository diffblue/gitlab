# frozen_string_literal: true

module Security
  class OrchestrationPolicyRuleSchedule < ApplicationRecord
    include Limitable
    include CronSchedulable
    include Gitlab::Utils::StrongMemoize

    self.table_name = 'security_orchestration_policy_rule_schedules'

    self.limit_name = 'security_policy_scan_execution_schedules'
    self.limit_scope = :security_orchestration_policy_configuration

    belongs_to :owner, class_name: 'User', foreign_key: 'user_id'
    belongs_to :security_orchestration_policy_configuration,
               class_name: 'Security::OrchestrationPolicyConfiguration',
               foreign_key: 'security_orchestration_policy_configuration_id'

    validates :owner, presence: true
    validates :security_orchestration_policy_configuration, presence: true
    validates :cron, cron: true, presence: true
    validates :policy_index, presence: true
    validates :rule_index, presence: true

    scope :runnable_schedules, -> { where("next_run_at < ?", Time.zone.now) }
    scope :with_owner, -> { includes(:owner) }
    scope :with_configuration_and_project_or_namespace, -> do
      includes(
        security_orchestration_policy_configuration: [:project, :namespace, :security_policy_management_project]
      )
    end

    def policy
      strong_memoize(:policy) do
        security_orchestration_policy_configuration.active_scan_execution_policies.at(policy_index)
      end
    end

    def applicable_branches(project = security_orchestration_policy_configuration.project)
      configured_branches = policy&.dig(:rules, rule_index, :branches)
      return [] if configured_branches.blank? || project.blank?

      branch_names = project.repository.branches

      configured_branches
        .flat_map { |pattern| RefMatcher.new(pattern).matching(branch_names).map(&:name) }
        .uniq
    end

    def applicable_agents
      policy&.dig(:rules, rule_index, :agents)
    end

    def for_agent?
      applicable_agents.present?
    end

    def cron_timezone
      Time.zone.name
    end

    def worker_cron_expression
      Settings.cron_jobs['security_orchestration_policy_rule_schedule_worker']['cron']
    end
  end
end
