# frozen_string_literal: true

# MergeRequests::ByApprovers class
#
# Used to filter MergeRequests collections by approvers

module MergeRequests
  class ByApproversFinder
    attr_reader :usernames, :ids

    def initialize(usernames, ids)
      @usernames = Array(usernames).map(&:to_s).uniq
      @ids = Array(ids).uniq
    end

    def execute(items)
      if by_no_approvers?
        without_approvers(items)
      elsif by_any_approvers?
        with_any_approvers(items)
      elsif ids.present?
        find_approvers_by_ids(items)
      elsif usernames.present?
        find_approvers_by_names(items)
      else
        items
      end
    end

    private

    def by_no_approvers?
      includes_custom_label?(IssuableFinder::Params::FILTER_NONE)
    end

    def by_any_approvers?
      includes_custom_label?(IssuableFinder::Params::FILTER_ANY)
    end

    def includes_custom_label?(label)
      ids.first.to_s.downcase == label || usernames.map(&:downcase).include?(label)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def without_approvers(items)
      items
        .left_outer_joins(:approval_rules)
        .joins('LEFT OUTER JOIN approval_project_rules ON approval_project_rules.project_id = merge_requests.target_project_id')
        .where(approval_merge_request_rules: { id: nil })
        .where(approval_project_rules: { id: nil })
    end

    def with_any_approvers(items)
      items.select_from_union(
        [
          items.joins(:approval_rules),
          items.joins('INNER JOIN approval_project_rules ON approval_project_rules.project_id = merge_requests.target_project_id')
        ])
    end

    def find_approvers_by_names(items)
      with_users_filtered_by_criteria(items) do |items_with_users|
        find_approvers_by_query(items_with_users, :username, usernames)
      end
    end

    def find_approvers_by_ids(items)
      with_users_filtered_by_criteria(items) do |items_with_users|
        find_approvers_by_query(items_with_users, :id, ids)
      end
    end

    def find_approvers_by_query(items, field, values)
      items
        .where(users: { field => values })
        .group('merge_requests.id')
        .having("COUNT(users.id) = ?", values.size)
    end

    def with_users_filtered_by_criteria(items)
      users_mrs = yield(items.joins(approval_rules: :users))
      group_users_mrs = yield(items.joins(approval_rules: { groups: :users }))

      mrs_without_overridden_rules = items.left_outer_joins(:approval_rules).where(approval_merge_request_rules: { id: nil })
      project_users_mrs = yield(mrs_without_overridden_rules.joins(target_project: { approval_rules: :users }))
      project_group_users_mrs = yield(mrs_without_overridden_rules.joins(target_project: { approval_rules: { groups: :users } }))

      items.select_from_union([users_mrs, group_users_mrs, project_users_mrs, project_group_users_mrs])
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
