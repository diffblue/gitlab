# frozen_string_literal: true

# Members added to groups and projects after the root group user cap has been reached
# will be added in an `awaiting` state.
#
# Root Group owners may activate those members at their discretion via this service, either
# individually or all awaiting members.
#
# User facing terminology differs to what we use in the backend:
#
# - activate => approve
# - awaiting => pending
module Members
  class ActivateService
    include BaseServiceUtility

    def initialize(group, member: nil, activate_all: false, current_user:)
      @group = group
      @member = member
      @current_user = current_user
      @activate_all = activate_all
    end

    def execute
      return error(_('No group provided')) unless group
      return error(_('You do not have permission to approve a member'), :forbidden) unless allowed?
      return error(_('No member provided')) unless activate_all || member

      if activate_memberships
        log_event

        success
      else
        error(_('No memberships found'), :bad_request)
      end
    end

    private

    attr_reader :current_user, :group, :member, :activate_all

    def activate_memberships
      memberships_found = false
      memberships = activate_all ? awaiting_memberships : scoped_memberships

      memberships.find_each do |member|
        memberships_found = true

        member.activate
      end

      memberships_found
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def scoped_memberships
      if member.invite?
        awaiting_memberships.where(invite_email: member.invite_email)
      else
        awaiting_memberships.where(user_id: member.user_id)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def awaiting_memberships
      ::Member.in_hierarchy(group).awaiting
    end

    def allowed?
      can?(current_user, :admin_group_member, group)
    end

    def log_event
      log_params = {
        group: group.id,
        approved_by: current_user.id
      }.tap do |params|
        params[:message] = activate_all ? 'Approved all pending group members' : 'Group member access approved'
        params[:member] = member.id unless activate_all
      end

      Gitlab::AppLogger.info(log_params)
    end
  end
end
