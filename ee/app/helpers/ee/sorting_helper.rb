# frozen_string_literal: true
module EE
  module SortingHelper
    extend ::Gitlab::Utils::Override

    override :sort_options_hash
    def sort_options_hash
      {
        sort_value_start_date => sort_title_start_date,
        sort_value_end_date   => sort_title_end_date,
        sort_value_less_weight => sort_title_less_weight,
        sort_value_more_weight => sort_title_more_weight,
        sort_value_weight      => sort_title_weight,
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
  end
end
