# frozen_string_literal: true

module Security
  class ApprovalGroupsFinder
    def initialize(group_ids:, group_paths:, user:, container:, search_globally:)
      @group_ids = group_ids
      @group_paths = group_paths
      @user = user
      @container = container
      @search_globally = search_globally
    end

    def execute(include_inaccessible: false)
      return global_groups(include_inaccessible) if global_groups?

      groups_within_container_hierarchy(include_inaccessible)
    end

    private

    attr_reader :group_ids,
      :group_paths,
      :user,
      :container

    def global_groups?
      @search_globally || user_namespace?
    end

    # rubocop: disable Layout/LineLength
    def global_groups(include_inaccessible)
      # Using GroupFinder here would make groups more restrictive than current features related to others approval project rules as in:
      # https://gitlab.com/gitlab-org/gitlab/-/blob/0aa924eaa1a4ca5ed6b226d826f7298ec847ea5f/ee/app/services/concerns/approval_rules/updater.rb#L44
      # Therefore data migrated from Vulnerability-Check into Scan result policies would be inconsistent.
      groups = include_inaccessible ? Group.all : Group.public_or_visible_to_user(user) # rubocop: disable Cop/GroupPublicOrVisibleToUser
      groups.by_ids_or_paths(group_ids, group_paths)
    end
    # rubocop: enable Layout/LineLength

    def groups_within_container_hierarchy(include_inaccessible)
      relation = container
                   .root_ancestor
                   .self_and_descendants
                   .by_ids_or_paths(group_ids, group_paths)

      return relation if include_inaccessible

      relation.public_or_visible_to_user(user)
    end

    def user_namespace?
      container.is_a?(Namespaces::UserNamespace)
    end
  end
end
