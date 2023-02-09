# frozen_string_literal: true

module EE
  module Members
    module UpdateService
      extend ActiveSupport::Concern

      def after_execute(action:, old_access_level:, old_expiry:, member:)
        super

        log_audit_event(action: action, old_access_level: old_access_level, old_expiry: old_expiry, member: member)
      end

      private

      def update_member(member, permission)
        if params.key?(:member_role_id)
          root = member.source.root_ancestor
          params.delete(:member_role_id) unless root.custom_roles_enabled?

          if params[:member_role_id] && !root.member_roles.find_by_id(params[:member_role_id])
            member.errors.add(:member_role, "not found")
            params.delete(:member_role_id)
          end
        end

        super
      end

      def log_audit_event(action:, old_access_level:, old_expiry:, member:)
        ::AuditEventService.new(
          current_user,
          member.source,
          action: action,
          old_access_level: old_access_level,
          old_expiry: old_expiry
        ).for_member(member).security_event
      end
    end
  end
end
