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

class EpicsFinder < IssuableFinder
  include TimeFrameFilter
  include Gitlab::Utils::StrongMemoize
  extend ::Gitlab::Utils::Override

  IID_STARTS_WITH_PATTERN = %r{\A(\d)+\z}.freeze

  def self.scalar_params
    @scalar_params ||= %i[
      parent_id
      author_id
      author_username
      label_name
      milestone_title
      start_date
      end_date
      search
      my_reaction_emoji
    ]
  end

  def self.array_params
    @array_params ||= { issues: [], label_name: [] }
  end

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

    items = init_collection
    items = filter_items(items)
    items = filter_negated_items(items)

    # This has to be last as we use a CTE as an optimization fence
    # for counts by passing the force_cte param
    # https://www.postgresql.org/docs/current/static/queries-with.html
    items = by_search(items)

    sort(items)
  end

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

  private

  def permissioned_related_groups
    strong_memoize(:permissioned_related_groups) do
      groups = related_groups

      # if user is member of top-level related group, he can automatically read
      # all epics in all subgroups
      next groups if can_read_all_epics_in_related_groups?(groups, include_confidential: false)

      next groups.public_to_user unless current_user
      next groups.public_to_user(current_user) unless groups.user_is_member(current_user).exists?

      # when traversal ids are enabled, we could avoid N+1 issue
      # by taking all public groups plus groups where user is member
      # and its descendants, but for now we have to check groups
      # one by one
      groups_user_can_read_epics(groups)
    end
  end

  def groups_user_can_read_epics(groups)
    # `same_root` should be set only if we are sure that all groups
    # in related_groups have the same ancestor root group
    ::Group.groups_user_can_read_epics(groups, current_user, same_root: true)
  end

  def filter_items(items)
    items = by_created_at(items)
    items = by_updated_at(items)
    items = by_author(items)
    items = by_timeframe(items)
    items = by_state(items)
    items = by_label(items)
    items = by_parent(items)
    items = by_child(items)
    items = by_iids(items)
    items = by_my_reaction_emoji(items)
    items = by_confidential(items)
    items = by_milestone(items)

    starts_with_iid(items)
  end

  def filter_negated_items(items)
    # API endpoints send in `nil` values so we test if there are any non-nil
    return items unless not_params&.values&.any?

    by_negated_my_reaction_emoji(items)
  end

  def starts_with_iid(items)
    return items unless params[:iid_starts_with].present?

    query = params[:iid_starts_with]
    raise ArgumentError unless self.class.valid_iid_query?(query)

    items.iid_starts_with(query)
  end

  def related_groups
    include_ancestors = params.fetch(:include_ancestor_groups, false)
    include_descendants = params.fetch(:include_descendant_groups, true)

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

  def parent_id?
    params[:parent_id].present?
  end

  def child_id?
    params[:child_id].present?
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_parent(items)
    return items unless parent_id?

    items.where(parent_id: params[:parent_id])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def by_child(items)
    return items unless child_id?

    ancestor_ids = Epic.find(params[:child_id]).ancestors.reselect(:id)
    items.where(id: ancestor_ids)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def with_confidentiality_access_check(epics, groups)
    return epics if can_read_all_epics_in_related_groups?(groups)

    epics.not_confidential_or_in_groups(groups_with_confidential_access(groups))
  end

  def groups_with_confidential_access(groups)
    return ::Group.none unless current_user

    # groups is an array, not a relation here so we have to use `map`
    group_ids = groups.map(&:id)
    GroupMember.by_group_ids(group_ids).by_user_id(current_user).non_guests.select(:source_id)
  end

  # @param include_confidential [Boolean] if this method should factor in
  # confidential issues. Setting this to `false` will mean that it only checks
  # the user can view all non-confidential epics within all of these groups. It
  # does not check that they can view confidential epics and as such may return
  # `true` even if `groups` contains a group where the user cannot view
  # confidential epics. As such you should only call this with `false` if you
  # are planning on filtering out confidential epics separately.
  def can_read_all_epics_in_related_groups?(groups, include_confidential: true)
    return true if @skip_visibility_check
    return false unless current_user

    # If a user is a member of a group, he also inherits access to all subgroups,
    # so here we check if user is member of the top-level group (from the
    # list of groups being requested) - this is checked by
    # `read_confidential_epic` policy. If that's the case we don't need to
    # check membership on subgroups.
    #
    # `groups` is a list of groups in the same group hierarchy, group is
    # highest in the group hierarchy except if we fetch ancestors - in that
    # case top-level group is group's root parent
    parent = params.fetch(:include_ancestor_groups, false) ? params.group.root_ancestor : params.group

    # If they can view confidential epics in this parent group they can
    # definitely view confidential epics in subgroups.
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

  def by_confidential(items)
    return items if params[:confidential].nil?

    params[:confidential] ? items.confidential : items.public_only
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_milestone(items)
    return items unless params[:milestone_title].present?

    milestones = Milestone.for_projects_and_groups(group_projects, permissioned_related_groups)
                          .where(title: params[:milestone_title])

    items.in_milestone(milestones)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def group_projects
    Project.in_namespace(permissioned_related_groups).with_issues_available_for_user(current_user)
  end

  override :feature_flag_scope
  def feature_flag_scope
    params.group
  end
end
