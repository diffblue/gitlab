# frozen_string_literal: true

module SystemAccess
  class BaseSaasGroupSyncWorker # rubocop:disable Scalability/IdempotentWorker
    include ::Gitlab::Utils::StrongMemoize

    private

    attr_accessor :top_level_group, :user

    def sync_and_update_default_membership
      response = sync_groups
      metadata = response.payload

      response = update_default_membership
      metadata[:updated] += 1 if response

      log_extra_metadata_on_done(:stats, metadata)
    end

    def sync_groups
      Groups::SyncService.new(
        top_level_group,
        user,
        group_links: group_links,
        manage_group_ids: manage_group_ids
      ).execute
    end

    # Reverts to the top-level default membership role if the user doesn't belong to any linked groups at the top level.
    # This ensures user has at least default membership role and doesn't lose access to the hierarchy.
    def update_default_membership
      return false unless top_level_group_contains_any_group_links?
      return false if top_level_group_in_group_links?
      return false if top_level_group.last_owner?(user)

      default_membership_role = top_level_group.saml_provider.default_membership_role
      return false if top_level_group.max_member_access_for_user(user) == default_membership_role

      top_level_group.add_member(user, default_membership_role)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def group_ids_with_any_links
      SamlGroupLink.by_group_id(group_ids_in_hierarchy).pluck(:group_id).uniq
    end
    strong_memoize_attr :group_ids_with_any_links

    def group_ids_in_hierarchy
      top_level_group.self_and_descendants.pluck(:id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def top_level_group_in_group_links?
      group_links.map(&:group_id).include?(top_level_group.id)
    end

    def top_level_group_contains_any_group_links?
      group_ids_with_any_links.include?(top_level_group.id)
    end

    # Only manage the top level group if there is a matching group link for the user.
    # Otherwise, the SyncService would remove the user completely.
    def manage_group_ids
      return group_ids_with_any_links if top_level_group_in_group_links?

      group_ids_with_any_links.reject { |id| id == top_level_group.id }
    end
  end
end
