# frozen_string_literal: true

# EpicsFinder
#
# Used to find and filter epics in a single group or a single group hierarchy.
# It can not be used for finding epics in multiple top-level groups.
#
# Params:
#   iids: integer[]
#   state: 'open' or 'closed' or 'all'
#   group_id: integer
#   parent_id: integer
#   child_id: integer
#   author_id: integer
#   author_username: string
#   label_name: string
#   milestone_title: string
#   search: string
#   sort: string
#   start_date: datetime
#   end_date: datetime
#   created_after: datetime
#   created_before: datetime
#   updated_after: datetime
#   updated_before: datetime
#   include_ancestor_groups: boolean
#   include_descendant_groups: boolean
#   starts_with_iid: string (containing a number)
#   confidential: boolean
#   hierarchy_order: :desc or :acs, default :acs when searched by child_id
#   top_level_hierarchy_only: boolean

class EpicsFinder < IssuableFinder
  include ::Epics::Findable
  include Gitlab::Utils::StrongMemoize
  extend ::Gitlab::Utils::Override

  IID_STARTS_WITH_PATTERN = %r{\A(\d)+\z}.freeze

  def self.valid_iid_query?(query)
    query.match?(IID_STARTS_WITH_PATTERN)
  end

  def klass
    Epic
  end

  def execute(skip_visibility_check: false)
    @skip_visibility_check = skip_visibility_check

    raise ArgumentError, 'group_id argument is missing' unless params[:group_id]
    return Epic.none unless Ability.allowed?(current_user, :read_epic, params.group)

    items = filter_and_search(init_collection)

    sort(items)
  end

  private

  def init_collection
    groups = if params[:iids].present?
               # If we are querying for specific iids, then we should only be looking at
               # those in the group, not any sub-groups (which can have identical iids).
               # The `params.group` method takes care of checking permissions
               [params.group]
             else
               permissioned_related_groups
             end

    epics = Epic.in_selected_groups(groups)
    with_confidentiality_access_check(epics, groups)
  end

  def permissioned_related_groups
    strong_memoize(:permissioned_related_groups) do
      groups = related_groups

      # if user is member of top-level related group, he can automatically read
      # all epics in all subgroups
      next groups if can_read_all_epics_in_related_groups?(include_confidential: false)

      next groups.public_to_user unless current_user
      next groups.public_to_user(current_user) unless groups.user_is_member(current_user).exists?

      # when traversal ids are enabled, we could avoid N+1 issue
      # by taking all public groups plus groups where user is member
      # and its descendants, but for now we have to check groups
      # one by one
      groups_user_can_read_epics(groups)
    end
  end
  alias_method :milestone_groups, :permissioned_related_groups

  def groups_user_can_read_epics(groups)
    # `same_root` should be set only if we are sure that all groups
    # in related_groups have the same ancestor root group
    Group.groups_user_can(groups, current_user, :read_epic, same_root: true)
  end

  def related_groups
    if include_ancestors && include_descendants
      params.group.self_and_hierarchy
    elsif include_ancestors
      params.group.self_and_ancestors
    elsif include_descendants
      params.group.self_and_descendants
    else
      Group.id_in(params.group.id)
    end
  end

  def count_key(value)
    last_value = Array(value).last

    if last_value.is_a?(Integer)
      Epic.states.invert[last_value].to_sym
    else
      last_value.to_sym
    end
  end

  def with_confidentiality_access_check(epics, groups)
    return epics if can_read_all_epics_in_related_groups?

    group_set =
      if Group.can_use_epics_filtering_optimization?(groups)
        related_groups
      else
        groups
      end

    epics.not_confidential_or_in_groups(groups_with_confidential_access(group_set))
  end

  def groups_with_confidential_access(groups)
    return ::Group.none unless current_user

    # `same_root` should be set only if we are sure that all groups
    # have the same ancestor root group. This is safe since it can only be the
    # single group sent in params, or permissioned_related_groups that can
    # include ancestors and descendants, so all have the same ancestor root group.
    # See https://gitlab.com/gitlab-org/gitlab/issues/11539
    Group.groups_user_can(
      groups,
      current_user,
      :read_confidential_epic,
      same_root: true
    )
  end

  # @param include_confidential [Boolean] if this method should factor in
  # confidential issues. Setting this to `false` will mean that it only checks
  # the user can view all non-confidential epics within all of these groups. It
  # does not check that they can view confidential epics and as such may return
  # `true` even if `groups` contains a group where the user cannot view
  # confidential epics. As such you should only call this with `false` if you
  # are planning on filtering out confidential epics separately.
  def can_read_all_epics_in_related_groups?(include_confidential: true)
    return true if @skip_visibility_check
    return false unless current_user

    # If a user is a member of a group, he also inherits access to all subgroups,
    # so here we check if user is member of the top-level group (from the
    # epic group hierarchy) - this is checked by
    # `read_confidential_epic` policy. If that's the case we don't need to
    # check membership on subgroups.
    parent = params.fetch(:include_ancestor_groups, false) ? params.group.root_ancestor : params.group

    return true if Ability.allowed?(current_user, :read_confidential_epic, parent)

    # If we don't account for confidential (assume it will be filtered later by
    # with_confidentiality_access_check) then as long as the user can see all
    # epics in this group they can see in all subgroups if member of parent group.
    # This is only true for private top level groups because it's possible that a top level public
    # group has private subgroups and therefore they would not necessarily be
    # able to read epics in the private subgroup even though they can in the
    # parent group.
    !include_confidential && Ability.allowed?(current_user, :list_subgroup_epics, parent)
  end

  override :sort
  def sort(items)
    return items if params[:hierarchy_order]

    super
  end

  def include_descendants
    @include_descendants ||= params.fetch(:include_descendant_groups, true)
  end

  def include_ancestors
    @include_ancestors ||= params.fetch(:include_ancestor_groups, false)
  end
end
