# frozen_string_literal: true

module TargetBranchRules
  class CreateService < TargetBranchRules::BaseService
    def execute
      return error_no_permissions unless authorized?

      if target_branch_rule.save
        success(payload: { target_branch_rule: target_branch_rule })
      else
        error(target_branch_rule&.errors&.full_messages || _('Failed to create target branch rule'))
      end
    end

    private

    def authorized?
      can?(current_user, :create_target_branch_rule, project)
    end

    def error_no_permissions
      error(_('You have insufficient permissions to create a target branch rule'))
    end

    def target_branch_rule
      @_target_branch_rule ||= project.target_branch_rules.new(params)
    end
  end
end
