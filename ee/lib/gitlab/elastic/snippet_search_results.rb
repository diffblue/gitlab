# frozen_string_literal: true

module Gitlab
  module Elastic
    class SnippetSearchResults < Gitlab::Elastic::SearchResults
      def objects(scope, page: 1, per_page: DEFAULT_PER_PAGE, preload_method: nil)
        page = (page || 1).to_i
        eager_load(snippet_titles, page, per_page, preload_method, project: [:route, :namespace])
      end

      def formatted_count(scope)
        elastic_search_limited_counter_with_delimiter(snippet_titles_count)
      end

      def snippet_titles_count
        limited_snippet_titles_count
      end

      def highlight_map(scope)
        snippet_titles.to_h { |x| [x[:_source][:id], x[:highlight]] }
      end

      private

      def snippet_titles
        Snippet.elastic_search(query, options: base_options)
      end

      def limited_snippet_titles_count
        @limited_snippet_titles_count ||= snippet_titles.total_count
      end
    end
  end
end
