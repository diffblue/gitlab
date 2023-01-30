# frozen_string_literal: true

# Switching a user's member state for all memberships belonging to the root group.
module Members
  class AwaitService
    include BaseServiceUtility

    def initialize(group, user:, current_user:)
      @group = group
      @user = user
      @current_user = current_user
    end

    def execute
      return error(_('No group provided')) unless group
      return error(_('No user provided')) unless user
      return error(_('You do not have permission to set a member awaiting')) unless allowed?
      return error(_('The last owner cannot be set to awaiting')) if group.last_owner?(user)
      return error(_('You cannot set yourself to awaiting')) if current_user == user

      set_memberships_to_awaiting
    end

    private

    attr_reader :group, :current_user, :user

    def set_memberships_to_awaiting
      # rubocop: disable CodeReuse/ActiveRecord
      affected_memberships = Member.where(id: memberships)
        .update_all(state: ::Member::STATE_AWAITING, updated_at: Time.current)
      # rubocop: enable CodeReuse/ActiveRecord

      if affected_memberships > 0
        UserProjectAccessChangedService.new(user.id).execute

        log_audit_event
        ServiceResponse.success
      else
        error(_('No memberships found'))
      end
    end

    def allowed?
      can?(current_user, :admin_group_member, group)
    end

    def error(message)
      ServiceResponse.error(message: message)
    end

    def memberships
      ::Member.in_hierarchy(group).with_user(user).non_awaiting
    end

    def log_audit_event
      ::Gitlab::Audit::Auditor.audit(
        name: 'change_membership_state',
        author: current_user,
        scope: group,
        target: user,
        message: 'Changed the membership state to awaiting'
      )
    end
  end
end
