# frozen_string_literal: true

module EE
  module Projects
    module BranchRule
      extend Forwardable

      def_delegators(:protected_branch, :approval_project_rules, :external_status_checks, :can_unprotect?)
    end
  end
end
