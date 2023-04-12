# frozen_string_literal: true

module EE::GroupMembersFinder
  extend ActiveSupport::Concern
  extend ::Gitlab::Utils::Override

  prepended do
    attr_reader :group
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def not_managed
    group.group_members.non_owners.joins(:user).merge(User.not_managed(group: group))
  end
  # rubocop: enable CodeReuse/ActiveRecord

  override :group_members_list
  def group_members_list
    return group.all_group_members if group.minimal_access_role_allowed?

    super
  end

  override :all_group_members
  def all_group_members(groups, shared_from_groups)
    return members_of_groups(groups, shared_from_groups) if group.minimal_access_role_allowed?

    super
  end

  override :apply_additional_filters
  def apply_additional_filters(filtered_members)
    members = super

    filter_by_enterprise_users(members)
  end

  private

  def filter_by_enterprise_users(members)
    filter_by_enterprise_param = ::Gitlab::Utils.to_boolean(params[:enterprise])

    return members if filter_by_enterprise_param.nil? # we require this param to be either `true` or `false`
    return members unless can_filter_by_enterprise?

    members.filter_by_enterprise_users(filter_by_enterprise_param)
  end

  def can_filter_by_enterprise?
    can_manage_members && group.root_ancestor.saml_enabled?
  end
end
