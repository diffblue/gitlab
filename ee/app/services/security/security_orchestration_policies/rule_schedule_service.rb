# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class RuleScheduleService < BaseProjectService
      def execute(schedule)
        return ServiceResponse.error(message: "No rules") unless rules = schedule&.policy&.fetch(:rules, nil)

        rule = rules[schedule.rule_index]

        return ServiceResponse.error(message: "No scheduled rules") unless schedule_rule?(rule)

        branches = branches_for(rule)
        actions = actions_for(schedule)
        schedule_errors = schedule_scan(actions, branches).select { |service_result| service_result[:status] == :error }

        return ServiceResponse.success if schedule_errors.blank?

        # The use of .pluck here is not for an Active record model but for a hash
        # rubocop: disable CodeReuse/ActiveRecord
        ServiceResponse.error(message: schedule_errors.pluck(:message))
        # rubocop: enable CodeReuse/ActiveRecord
      end

      private

      def schedule_rule?(rule)
        rule.present? && rule[:type] == Security::ScanExecutionPolicy::RULE_TYPES[:schedule]
      end

      def actions_for(schedule)
        policy = schedule.policy
        return [] if policy.blank?

        policy[:actions]
      end

      def branches_for(rule)
        ::Security::SecurityOrchestrationPolicies::PolicyBranchesService
          .new(project: project)
          .scan_execution_branches([rule])
      end

      def schedule_scan(actions, branches)
        return [] if actions.blank?

        branches.map do |branch|
          ::Security::SecurityOrchestrationPolicies::CreatePipelineService
            .new(project: project, current_user: current_user, params: { actions: actions, branch: branch })
            .execute
        end
      end
    end
  end
end
