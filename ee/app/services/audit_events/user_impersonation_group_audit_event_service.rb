# frozen_string_literal: true

# Creates audit events at both the instance level
# and for all of a user's groups when the user is impersonated.
module AuditEvents
  class UserImpersonationGroupAuditEventService
    def initialize(impersonator:, user:, remote_ip:, action: :started, created_at:)
      @impersonator = impersonator
      @user = user
      @remote_ip = remote_ip
      @action = action.to_s
      @created_at = created_at
    end

    def execute
      log_instance_audit_event
      log_groups_audit_events
    end

    def log_instance_audit_event
      ::Gitlab::Audit::Auditor.audit({
        name: "user_impersonation",
        author: @impersonator,
        scope: @impersonator,
        target: @user,
        message: "#{@action.capitalize} Impersonation",
        created_at: @created_at
      })
    end

    def log_groups_audit_events
      # Limited to 20 groups because we can't batch insert audit events
      # https://gitlab.com/gitlab-org/gitlab/-/issues/352483
      @user.groups.first(20).each do |group|
        audit_context = {
          name: "user_impersonation",
          author: @impersonator,
          scope: group,
          target: @user,
          message: "Instance administrator #{@action} impersonation of #{@user.username}",
          created_at: @created_at
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end
    end
  end
end
