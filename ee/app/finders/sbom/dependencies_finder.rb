# frozen_string_literal: true

module Sbom
  class DependenciesFinder
    def initialize(project_or_group, params: {})
      @project_or_group = project_or_group
      @params = params
    end

    def execute
      sbom_occurrences = filtered_collection

      case params[:sort_by]
      when 'name'
        sbom_occurrences.order_by_component_name(params[:sort])
      when 'packager'
        sbom_occurrences.order_by_package_name(params[:sort])
      else
        sbom_occurrences.order_by_id
      end
    end

    private

    attr_reader :project_or_group, :params

    def filtered_collection
      return project_or_group.sbom_occurrences unless params[:package_managers].present?

      project_or_group.sbom_occurrences.filter_by_package_managers(params[:package_managers])
    end
  end
end
