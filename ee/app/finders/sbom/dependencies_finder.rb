# frozen_string_literal: true

module Sbom
  class DependenciesFinder
    def initialize(project, params: {})
      @project = project
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

    attr_reader :project, :params

    def filtered_collection
      return project.sbom_occurrences unless params[:package_managers].present?

      project.sbom_occurrences.filter_by_package_managers(params[:package_managers])
    end
  end
end
