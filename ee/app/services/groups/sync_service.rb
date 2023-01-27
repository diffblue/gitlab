# frozen_string_literal: true

#
# Usage example:
#
# Groups::SyncService.new(
#   top_level_group, user,
#   group_links: array_of_group_links,
#   manage_group_ids: array_of_group_ids
# ).execute
#
# Given group links must respond to `group_id` and `access_level`.
#
# This is a generic group sync service, reusable by many IdP-specific
# implementations. The worker (caller) is responsible for providing the
# specific group links, which this service then iterates over
# and adds/removes users from respective groups. Users will only be
# removed from groups matching `manage_group_ids`.
#
# See `GroupSamlGroupSyncWorker` for an example.
#
module Groups
  class SyncService < Groups::BaseService
    include Gitlab::Utils::StrongMemoize
    extend Gitlab::Utils::Override

    attr_reader :updated_membership

    override :initialize
    def initialize(group, user, params = {})
      @updated_membership = {
        added: 0,
        updated: 0,
        removed: 0
      }

      super
    end

    def execute
      return unless group

      remove_old_memberships
      update_current_memberships

      ServiceResponse.success(payload: updated_membership)
    end

    private

    def remove_old_memberships
      members_to_remove.each do |member|
        Members::DestroyService.new(current_user).execute(member, skip_authorization: true)

        next unless member.destroyed?

        log_membership_update(
          group_id: member.source_id,
          action: :removed,
          prior_access_level: member.access_level,
          access_level: nil
        )
      end
    end

    def update_current_memberships
      group_links_by_group.each do |group, group_links|
        access_level = max_access_level(group_links)
        existing_member = existing_member_by_group(group)

        next if correct_access_level?(existing_member, access_level) || group.last_owner?(current_user)

        add_member(group, access_level, existing_member)
      end
    end

    def add_member(group, access_level, existing_member)
      member = group.add_member(current_user, access_level)

      return member unless member.persisted? && member.access_level == access_level

      log_membership_update(
        group_id: group.id,
        action: (existing_member ? :updated : :added),
        prior_access_level: existing_member&.access_level,
        access_level: access_level
      )
    end

    def correct_access_level?(member, access_level)
      member && member.access_level == access_level
    end

    def members_to_remove
      existing_members.select do |member|
        group_id = member.source_id

        !member_in_groups_to_be_updated?(group_id) && manage_group?(group_id)
      end
    end

    def member_in_groups_to_be_updated?(group_id)
      group_links_by_group.keys.map(&:id).include?(group_id)
    end

    def manage_group?(group_id)
      params[:manage_group_ids].include?(group_id)
    end

    def existing_member_by_group(group)
      existing_members.find { |member| member.source_id == group.id }
    end

    def existing_members
      strong_memoize(:existing_members) do
        group.members_with_descendants.with_user(current_user).to_a
      end
    end

    def group_links_by_group
      strong_memoize(:group_links_by_group) do
        params[:group_links].group_by(&:group)
      end
    end

    def max_access_level(group_links)
      group_links.map(&:access_level_before_type_cast).max
    end

    def log_membership_update(group_id:, action:, prior_access_level:, access_level:)
      @updated_membership[action] += 1

      Gitlab::AppLogger.debug(message: "#{self.class.name} User: #{current_user.username} (#{current_user.id}), Action: #{action}, Group: #{group_id}, Prior Access: #{prior_access_level}, New Access: #{access_level}")
    end
  end
end
