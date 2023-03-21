# frozen_string_literal: true

module EE
  module Members
    module CreateService
      private

      def validate_invitable!
        super

        check_membership_lock!
        check_quota!
      end

      def check_quota!
        return unless invite_quota_exceeded?

        raise ::Members::CreateService::TooManyInvitesError,
              format(
                s_("AddMember|Invite limit of %{daily_invites} per day exceeded"),
                daily_invites: source.actual_limits.daily_invites
              )
      end

      def check_membership_lock!
        return unless source.membership_locked?

        @membership_locked = true # rubocop:disable Gitlab/ModuleWithInstanceVariables
        raise ::Members::CreateService::MembershipLockedError
      end

      def invite_quota_exceeded?
        return if source.actual_limits.daily_invites == 0

        invite_count = ::Member.invite.created_today.in_hierarchy(source).count

        source.actual_limits.exceeded?(:daily_invites, invite_count + invites.count)
      end

      def after_execute(member:)
        super

        log_audit_event(member: member)
      end

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
