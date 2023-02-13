# frozen_string_literal: true

module Sbom
  class DependenciesFinder
    def initialize(project, params: {})
      @project = project
      @params = params
    end

    def execute
      project.sbom_occurrences
        .order_by_id
    end

    private

    attr_reader :project, :params
  end
end
