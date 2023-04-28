# frozen_string_literal: true

module Sbom
  class DependenciesFinder
    def initialize(project, params: {})
      @project = project
      @params = params
    end

    def execute
      sbom_occurrences = project.sbom_occurrences
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
  end
end
