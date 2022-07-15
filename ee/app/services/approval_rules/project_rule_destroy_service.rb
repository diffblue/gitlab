# frozen_string_literal: true

module ApprovalRules
  class ProjectRuleDestroyService < ::BaseService
    attr_reader :rule

    def initialize(approval_rule, current_user)
      @rule = approval_rule
      super(approval_rule.project, current_user)
    end

    def execute
      ApplicationRecord.transaction do
        # Removes only MR rules associated with project rule
        remove_associated_approval_rules_from_unmerged_merge_requests

        rule.destroy
      end

      if rule.destroyed?
        audit_deletion
        success
      else
        error(rule.errors.messages)
      end
    end

    private

    def remove_associated_approval_rules_from_unmerged_merge_requests
      ApprovalMergeRequestRule
        .from_project_rule(rule)
        .for_unmerged_merge_requests
        .delete_all
    end

    def audit_deletion
      audit_context = {
        name: 'approval_rule_deleted',
        author: current_user,
        scope: rule.project,
        target: rule,
        message: 'Deleted approval rule'
      }

      ::Gitlab::Audit::Auditor.audit(audit_context)
    end
  end
end
