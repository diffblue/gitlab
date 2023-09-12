# frozen_string_literal: true

module TargetBranchRules
  class DestroyService < TargetBranchRules::BaseService
    def execute
      return error_no_permissions unless authorized?
      return error(_('Target branch rule does not exist')) unless target_branch_rule

      if target_branch_rule.destroy
        success(payload: { target_branch_rule: target_branch_rule })
      else
        error(target_branch_rule.errors&.full_messages.presence || _('Failed to delete target branch rule'))
      end
    end

    private

    def authorized?
      can?(current_user, :admin_target_branch_rule, project)
    end

    def error_no_permissions
      error(_('You have insufficient permissions to delete a target branch rule'))
    end

    def target_branch_rule
      @_target_branch_rule ||= project.target_branch_rules.find_by_id(params[:id])
    end
  end
end
