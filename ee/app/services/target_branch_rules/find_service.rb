# frozen_string_literal: true

module TargetBranchRules
  class FindService < TargetBranchRules::BaseService
    def execute(branch)
      return default_branch unless authorized?

      target_branch_rule = target_branch_rules.detect do |rule|
        RefMatcher.new(rule.name).matches?(branch)
      end

      target_branch_rule&.target_branch || default_branch
    end

    def authorized?
      can?(current_user, :read_target_branch_rule, project)
    end

    private

    def default_branch
      @project.default_branch
    end

    def target_branch_rules
      project.target_branch_rules
    end
  end
end
