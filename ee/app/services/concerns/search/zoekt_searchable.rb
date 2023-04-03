# frozen_string_literal: true

module Search
  module ZoektSearchable
    def use_zoekt?
      return false if params[:basic_search]
      return false if params[:advanced_search]
      return false unless ::Feature.enabled?(:search_code_with_zoekt, current_user)
      return false unless ::License.feature_available?(:zoekt_code_search)

      scope == 'blobs' &&
        zoekt_searchable_scope.respond_to?(:use_zoekt?) &&
        zoekt_searchable_scope.use_zoekt?
    end

    def zoekt_searchable_scope
      raise NotImplementedError
    end

    def zoekt_projects
      raise NotImplementedError
    end

    def zoekt_search_results
      ::Gitlab::Zoekt::SearchResults.new(
        current_user,
        params[:search],
        zoekt_projects,
        order_by: params[:order_by],
        sort: params[:sort],
        filters: { language: params[:language] }
      )
    end
  end
end
