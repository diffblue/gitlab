# frozen_string_literal: true
module EE
  module SortingTitlesValuesHelper
    def sort_title_start_date
      s_('SortOptions|Start date')
    end

    def sort_title_end_date
      s_('SortOptions|Due date')
    end

    def sort_title_less_weight
      s_('SortOptions|Less weight')
    end

    def sort_title_more_weight
      s_('SortOptions|More weight')
    end

    def sort_title_weight
      s_('SortOptions|Weight')
    end

    def sort_title_blocking
      s_('SortOptions|Blocking')
    end

    def sort_title_project_name
      s_('SortOptions|Project')
    end

    def sort_title_version
      s_('SortOptions|Version')
    end

    def sort_title_type
      s_('SortOptions|Type')
    end

    def sort_value_start_date
      'start_date_asc'
    end

    def sort_value_end_date
      'end_date_asc'
    end

    def sort_value_end_date_later
      'end_date_desc'
    end

    def sort_value_less_weight
      'weight_asc'
    end

    def sort_value_more_weight
      'weight_desc'
    end

    def sort_value_weight
      'weight'
    end

    def sort_value_blocking_desc
      'blocking_issues_desc'
    end

    def sort_value_project_name_asc
      'project_name_asc'
    end

    def sort_value_project_name_desc
      'project_name_desc'
    end

    def sort_value_version_asc
      'version_asc'
    end

    def sort_value_version_desc
      'version_desc'
    end

    def sort_value_type_asc
      'type_asc'
    end

    def sort_value_type_desc
      'type_desc'
    end
  end
end
