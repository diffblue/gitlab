# frozen_string_literal: true

# Module to include in epic finder classes to provide access checks
# to epics. Finder classes which use this module
# can use the epics_with_read_access method to return the collection of epics
# defined in epics_collection() excluding the ones that user have no read access to.
# This includes confidentiality access.
#
# Params supported:
# include_descendant_groups: When `false` the epics that belongs to descendant groups
# defined in group_descendants() will be excluded. Default value is `true`.
# include_ancestor_groups: When `false` the epics that belongs to ancestors groups
# defined in group_ancestors() will be excluded. Default value is `true`.

module Epics
  module WithAccessCheck
    extend ActiveSupport::Concern
    include Gitlab::Utils::StrongMemoize

    private

    def epics_with_read_access(preload: false)
      groups_with_read_access = if current_user.present?
                                  permissioned_groups(preload: preload)
                                else
                                  epic_groups.public_to_user
                                end

      permissioned_epics = epics_collection.in_selected_groups(groups_with_read_access)

      with_confidentiality_access(permissioned_epics, preload: preload)
    end

    def with_confidentiality_access(epics, preload: false)
      return epics if epics.confidential.none?

      with_confidential_access = permissioned_groups(ability: :read_confidential_epic, preload: preload)

      epics.not_confidential_or_in_groups(with_confidential_access)
    end

    def permissioned_groups(ability: :read_epic, preload: false)
      groups = preload ? Group.preload_root_saml_providers(epic_groups) : epic_groups

      Group.groups_user_can(groups, current_user, ability)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def epic_groups
      strong_memoize(:epic_groups) do
        Group.for_epics(epics_collection_for_groups).where.not(id: groups_to_exclude).distinct
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def epics_collection
      raise NotImplementedError
    end

    # for epic ancestors finder we need to use different sub-query for getting
    # groups, because epics_collection uses ordering by hierarchy. And the
    # problem is that if (hierarchy_order: :asc) is used for getting groups,
    # then ambiguous group_id column is included.
    def epics_collection_for_groups
      raise NotImplementedError
    end

    def groups_to_exclude
      groups = []

      groups += group_ancestors unless include_ancestors
      groups += group_descendants unless include_descendants

      groups
    end

    def include_descendants
      @include_descendants ||= params.fetch(:include_descendant_groups, true)
    end

    def include_ancestors
      @include_ancestors ||= params.fetch(:include_ancestor_groups, true)
    end

    def group_ancestors
      @group_ancestors ||= base_epic.group.ancestors
    end

    def group_descendants
      @group_descendants ||= base_epic.group.descendants
    end

    def base_epic
      raise NotImplementedError
    end
  end
end
