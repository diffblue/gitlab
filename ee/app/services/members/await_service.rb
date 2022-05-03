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

      set_memberships_to_awaiting
    end

    private

    attr_reader :group, :current_user, :user

    def set_memberships_to_awaiting
      memberships_found = false

      memberships.find_each do |member|
        memberships_found = true
        member.wait
      end

      if memberships_found
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
