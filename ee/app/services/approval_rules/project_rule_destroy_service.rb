# frozen_string_literal: true

module ApprovalRules
  class ProjectRuleDestroyService < ::BaseService
    attr_reader :rule

    def initialize(approval_rule)
      @rule = approval_rule
    end

    def execute
      ApplicationRecord.transaction do
        # Removes only MR rules associated with project rule
        remove_associated_approval_rules_from_unmerged_merge_requests

        rule.destroy
      end

      if rule.destroyed?
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
  end
end
