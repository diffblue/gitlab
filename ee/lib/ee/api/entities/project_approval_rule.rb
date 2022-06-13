# frozen_string_literal: true

module EE
  module API
    module Entities
      class ProjectApprovalRule < ApprovalRule
        expose :protected_branches, using: ::API::Entities::ProtectedBranch, if: -> (rule, _) { rule.project.multiple_approval_rules_available? }
        expose :applies_to_all_protected_branches, if: -> (rule, _) { ::Feature.enabled?(:project_approval_rule_all_protected_branches, rule.project.group) }
      end
    end
  end
end
