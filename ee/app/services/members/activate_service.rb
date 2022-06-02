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

    def initialize(group, user: nil, member: nil, activate_all: false, current_user:)
      @group = group
      @member = member
      @user = user
      @current_user = current_user
      @activate_all = activate_all
    end

    def execute
      return error(_('No group provided')) unless group
      return error(_('You do not have permission to approve a member'), :forbidden) unless allowed?
      return error(_('You can only approve an indivdual user, member, or all members')) unless valid_params?
      return error(_('You cannot approve all pending members on a free plan')) if activate_all && group.free_plan?
      return error(_('There is no seat left to activate the member')) unless has_capacity_left?

      activate_memberships
    end

    private

    attr_reader :current_user, :group, :member, :activate_all, :user

    def valid_params?
      [user, member, activate_all].count { |v| !!v } == 1
    end

    def activate_memberships
      memberships = activate_all ? awaiting_memberships : scoped_memberships

      affected_user_ids = Set.new

      memberships.find_each do |member|
        member.update_columns(state: ::Member::STATE_ACTIVE, updated_at: Time.current)

        affected_user_ids.add(member.user_id)
      end

      if !affected_user_ids.empty?
        UserProjectAccessChangedService.new(affected_user_ids.to_a).execute(blocking: false)

        log_audit_event unless activate_all
        log_event
        success
      else
        error(_('No memberships found'), :bad_request)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def scoped_memberships
      return awaiting_memberships.where(user: user) if user

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

    def has_capacity_left?
      return true if activate_all && !group.free_plan?

      group.root_ancestor.capacity_left_for_user?(user || member.user)
    end

    def log_event
      log_params = {
        group: group.id,
        approved_by: current_user.id
      }.tap do |params|
        params[:message] = activate_all ? 'Approved all pending group members' : 'Group member access approved'
        unless activate_all
          params[:member] = member.id if member
          params[:user] = user.id if user
        end
      end
      Gitlab::AppLogger.info(log_params)
    end

    def log_audit_event
      target = user || member&.user
      return unless target

      ::Gitlab::Audit::Auditor.audit(
        name: 'change_membership_state',
        author: current_user,
        scope: group,
        target: target,
        message: 'Changed the membership state to active'
      )
    end
  end
end
