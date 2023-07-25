# frozen_string_literal: true

# This finder returns all users that are related to a given group because:
# 1. They are members of the group, its sub-groups, or its ancestor groups
# 2. They are members of a group that is invited to the group, its sub-groups, or its ancestors
# 3. They are members of a project that belongs to the group
# 4. They are members of a group that is invited to the group's descendant projects
#
# These users are not necessarily members of the given group and may not have access to the group
# so this should not be used for access control
module Autocomplete
  class GroupUsersFinder
    def initialize(group:)
      @group = group
    end

    def execute
      members = Member.from_union(member_relations, remove_duplicates: false)

      User.id_in(members.select(:user_id))
    end

    private

    def member_relations
      relations = [
        @group.hierarchy_members.select(:user_id),
        members_from_descendant_projects.select(:user_id)
      ]

      if Feature.enabled?(:include_descendant_shares_in_user_autocomplete, @group)
        relations << members_from_hierarchy_group_shares.select(:user_id)
        relations << members_from_descendant_project_shares.select(:user_id)
      else
        relations << @group.members_from_self_and_ancestor_group_shares.reselect(:user_id)
      end

      relations
    end

    def members_from_hierarchy_group_shares
      source_ids = @group.self_and_hierarchy.select(:id)
      invited_groups = GroupGroupLink.for_shared_groups(source_ids).select(:shared_with_group_id)

      GroupMember
        .with_source_id(invited_groups)
        .without_invites_and_requests
    end

    def members_from_descendant_projects
      ProjectMember
        .with_source_id(@group.all_projects)
        .without_invites_and_requests
    end

    def members_from_descendant_project_shares
      descendant_project_invited_groups = ProjectGroupLink.for_projects(@group.all_projects).select(:group_id)

      GroupMember
        .with_source_id(descendant_project_invited_groups)
        .without_invites_and_requests
    end
  end
end
