# frozen_string_literal: true

module Sbom
  class DependenciesFinder
    DEFAULT_PAGE = 1
    DEFAULT_PER_PAGE = 20

    def initialize(project, params: {})
      @project = project
      @params = params
    end

    def execute
      project.sbom_occurrences
        .page(page)
        .per(per_page)
    end

    private

    attr_reader :project, :params

    def page
      @page ||= params[:page] || DEFAULT_PAGE
    end

    def per_page
      @per_page ||= params[:per_page] || DEFAULT_PER_PAGE
    end
  end
end
