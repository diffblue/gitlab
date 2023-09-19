# frozen_string_literal: true

module Audit
  module PushRules
    class ProjectPushRulesChangesAuditor < BasePushRulesChangesAuditor
      def execute
        return if model.blank? || model.project.nil?

        audit_changes(
          :commit_committer_check,
          as: 'reject unverified users',
          entity: model.project,
          model: model,
          event_type: 'project_push_rules_commit_committer_check_updated'
        )
      end

      private

      def target_details
        model.project.full_path
      end
    end
  end
end
