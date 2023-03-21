# frozen_string_literal: true

module EE
  module Members
    module ApproveAccessRequestService
      def after_execute(member:, skip_log_audit_event: false)
        super

        log_audit_event(member: member) unless skip_log_audit_event
      end

      private

      def log_audit_event(member:)
        audit_context = {
          name: 'member_created',
          author: current_user || ::Gitlab::Audit::UnauthenticatedAuthor.new(name: '(System)'),
          scope: member.source,
          target: member.user || ::Gitlab::Audit::NullTarget.new,
          target_details: member.user ? member.user.name : 'Deleted User',
          message: 'Membership created',
          additional_details: {
            add: 'user_access',
            as: ::Gitlab::Access.options_with_owner.key(member.access_level.to_i),
            member_id: member.id
          }
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end
    end
  end
end
