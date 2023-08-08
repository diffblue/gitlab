# frozen_string_literal: true

module SystemAccess
  class BaseGlobalGroupSyncWorker # rubocop:disable Scalability/IdempotentWorker
    include ::Gitlab::Utils::StrongMemoize

    private

    def groups_to_sync?
      group_links.any? || group_ids_by_root_ancestor_id.any?
    end

    def sync_groups
      group_ids_to_manage = group_ids_by_root_ancestor_id.dup

      # Sync groups user for which user should be a member
      group_links_by_root_ancestor.each do |root_ancestor, group_links|
        Groups::SyncService.new(
          root_ancestor, user,
          group_links: group_links, manage_group_ids: group_ids_to_manage.delete(root_ancestor.id)
        ).execute
      end

      return if group_ids_to_manage.empty?

      root_ancestors = preload_groups(group_ids_to_manage.keys)

      # Sync groups with links for which user should not be a member
      group_ids_to_manage.each do |root_ancestor_id, group_ids|
        Groups::SyncService.new(
          root_ancestors[root_ancestor_id], user, group_links: [], manage_group_ids: group_ids
        ).execute
      end
    end

    def group_ids_by_root_ancestor_id
      grouped = {}
      groups = Group.with_saml_group_links.select(:id, 'traversal_ids[1] as root_id')

      groups.each do |group|
        grouped[group.root_id] ||= []

        grouped[group.root_id].push(group.id)
      end

      grouped
    end
    strong_memoize_attr :group_ids_by_root_ancestor_id

    def group_links_by_root_ancestor
      grouped = {}
      groups = group_links.map(&:group)
      Preloaders::GroupRootAncestorPreloader.new(groups, [:route]).execute

      group_links.each do |link|
        root_ancestor = link.group.root_ancestor
        grouped[root_ancestor] ||= []

        grouped[root_ancestor].push(link)
      end

      grouped
    end
    strong_memoize_attr :group_links_by_root_ancestor

    def preload_groups(group_ids)
      Group.by_id(group_ids).index_by(&:id)
    end
  end
end
