# frozen_string_literal: true

class BilledUsersFinder
  def initialize(group, search_term: nil, order_by: 'name_asc', include_awaiting_members: false)
    @group = group
    @search_term = search_term
    @order_by = order_by
    @include_awaiting_members = include_awaiting_members
  end

  def execute
    return {} unless user_ids.any?

    users = ::User.id_in(user_ids)
    users = users.search(search_term) if search_term

    {
      users: users.sort_by_attribute(order_by),
      group_member_user_ids: group_billed_user_ids[:group_member_user_ids],
      project_member_user_ids: group_billed_user_ids[:project_member_user_ids],
      shared_group_user_ids: group_billed_user_ids[:shared_group_user_ids],
      shared_project_user_ids: group_billed_user_ids[:shared_project_user_ids]
    }
  end

  private

  attr_reader :group, :search_term, :order_by, :include_awaiting_members

  def user_ids
    group_billed_user_ids[:user_ids] + awaiting_user_ids
  end

  def group_billed_user_ids
    @group_billed_user_ids ||= group.billed_user_ids
  end

  def awaiting_user_ids
    return [] unless include_awaiting_members

    group.awaiting_user_ids
  end
end
