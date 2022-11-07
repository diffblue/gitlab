# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class RuleScheduleService < BaseContainerService
      def execute(schedule)
        branches = schedule.applicable_branches(container)
        actions = actions_for(schedule)
        schedule_scan(actions, branches)
      end

      private

      def actions_for(schedule)
        policy = schedule.policy
        return [] if policy.blank?

        policy[:actions]
      end

      def schedule_scan(actions, branches)
        return if actions.blank?

        branches.each do |branch|
          ::Security::SecurityOrchestrationPolicies::CreatePipelineService
            .new(project: container, current_user: current_user, params: { actions: actions, branch: branch })
            .execute
        end
      end
    end
  end
end
