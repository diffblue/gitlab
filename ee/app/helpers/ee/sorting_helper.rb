# frozen_string_literal: true
module EE
  module SortingHelper
    extend ::Gitlab::Utils::Override

    override :sort_options_hash
    def sort_options_hash
      {
        sort_value_start_date => sort_title_start_date,
        sort_value_end_date => sort_title_end_date,
        sort_value_less_weight => sort_title_less_weight,
        sort_value_more_weight => sort_title_more_weight,
        sort_value_weight => sort_title_weight,
        sort_value_blocking_desc => sort_title_blocking
      }.merge(super)
    end

    override :issuable_reverse_sort_order_hash
    def issuable_reverse_sort_order_hash
      {
        sort_value_weight => sort_value_more_weight
      }.merge(super)
    end

    override :issuable_sort_option_overrides
    def issuable_sort_option_overrides
      {
        sort_value_more_weight => sort_value_weight
      }.merge(super)
    end

    override :sort_direction_icon
    def sort_direction_icon(sort_value)
      if sort_value == sort_value_weight
        'sort-lowest'
      else
        super
      end
    end

    override :issuable_sort_options
    def issuable_sort_options(viewing_issues, viewing_merge_requests)
      options = super
      options.concat([weight_option]) if can_sort_by_issue_weight?(viewing_issues)
      options.concat([blocking_option]) if viewing_issues

      options
    end

    override :can_sort_by_issue_weight?
    def can_sort_by_issue_weight?(viewing_issues)
      viewing_issues && (@project || @group)&.licensed_feature_available?(:issue_weights)
    end

    def weight_option
      { value: sort_value_weight, text: sort_title_weight, href: page_filter_path(sort: sort_value_weight) }
    end

    def blocking_option
      {
        value: sort_value_blocking_desc,
        text: sort_title_blocking,
        href: page_filter_path(sort: sort_value_blocking_desc)
      }
    end
  end
end
