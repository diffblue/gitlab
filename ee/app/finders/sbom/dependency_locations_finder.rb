# frozen_string_literal: true

module Sbom
  class DependencyLocationsFinder
    DEFAULT_PER_PAGE = 50

    def initialize(namespace:, params: {})
      @namespace = namespace
      @params = params
    end

    def execute
      Sbom::Occurrence
        .filter_by_search_with_component_and_group(params[:search], params[:component_id], namespace)
        .limit(DEFAULT_PER_PAGE)
    end

    private

    attr_reader :namespace, :params
  end
end
