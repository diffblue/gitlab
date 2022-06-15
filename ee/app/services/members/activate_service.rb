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

    def self.for_invite(group, invite_email:)
      memberships = ::Member.in_hierarchy(group).awaiting.invite.where(invite_email: invite_email) # rubocop: disable CodeReuse/ActiveRecord

      new(group, memberships: memberships)
    end

    def self.for_users(group, users:)
      memberships = ::Member.in_hierarchy(group).awaiting.with_user(users)

      new(group, memberships: memberships)
    end

    def self.for_group(group)
      memberships = ::Member.in_hierarchy(group).awaiting

      new(group, memberships: memberships)
    end

    def initialize(group, memberships:)
      @group = group
      @memberships = memberships
    end

    private_class_method :new

    def execute(current_user:, skip_authorization: false)
      @current_user = current_user
      @skip_authorization = skip_authorization

      return error(_('You do not have permission to approve a member'), :forbidden) unless allowed?
      return error(_('There is no seat left to activate the member')) unless has_capacity_left?
      return error(_('No memberships found'), :bad_request) if memberships.empty?

      activate_memberships
      update_user_project_access
      log_audit_event
      log_event

      success
    end

    private

    attr_reader :group, :memberships, :current_user, :affected_members, :skip_authorization

    def activate_memberships
      @affected_members = memberships.to_a

      ::Member.where(id: memberships).update_all(state: ::Member::STATE_ACTIVE, updated_at: Time.current) # rubocop: disable CodeReuse/ActiveRecord
    end

    def allowed?
      return true if skip_authorization

      can?(current_user, :admin_group_member, group)
    end

    def has_capacity_left?
      return true unless free_user_cap.enforce_cap?

      # A user could have an active and awaiting memberships at the same time.
      # If there is at least one active membership for a user, a seat is already in use.
      # We therefore can only count users towards the seat limit if there is no active membership.
      # rubocop: disable CodeReuse/ActiveRecord
      active_user_ids = ::Member.in_hierarchy(group).active_state.select(:user_id).distinct
      to_activate_count = memberships.excluding_users(active_user_ids).distinct.count(:user_id)
      # rubocop: enable CodeReuse/ActiveRecord

      to_activate_count <= free_user_cap.remaining_seats
    end

    def free_user_cap
      @free_user_cap ||= Namespaces::FreeUserCap::Standard.new(group)
    end

    def update_user_project_access
      affected_user_ids = affected_members.map(&:user_id).compact.uniq

      UserProjectAccessChangedService.new(affected_user_ids).execute(blocking: false)
    end

    def log_event
      log_params = {
        group: group.id,
        approved_by: current_user.id,
        message: 'Group member access approved',
        members: affected_members.map(&:id)
      }

      Gitlab::AppLogger.info(log_params)
    end

    def log_audit_event
      affected_members.each do |member|
        ::Gitlab::Audit::Auditor.audit(
          name: 'change_membership_state',
          author: current_user,
          scope: group,
          target: member,
          message: 'Changed the membership state to active'
        )
      end
    end
  end
end
