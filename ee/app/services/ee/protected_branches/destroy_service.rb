# frozen_string_literal: true

module EE
  module ProtectedBranches
    module DestroyService
      extend ::Gitlab::Utils::Override
      include Loggable

      override :execute
      def execute(protected_branch)
        super(protected_branch).tap do |protected_branch_service|
          # DestroyService returns the value of #.destroy instead of the
          # instance, in comparison with the other services
          # (CreateService and UpdateService) so if the destroy service
          # doesn't succeed the value will be false instead of an instance
          log_audit_event(protected_branch_service, :remove) if protected_branch_service
        end
      end

      def after_execute(*)
        sync_scan_finding_approval_rules
      end
    end
  end
end
