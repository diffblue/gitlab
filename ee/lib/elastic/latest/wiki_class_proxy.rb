# frozen_string_literal: true

module Elastic
  module Latest
    class WikiClassProxy < ApplicationClassProxy
      include GitClassProxy
      include Routing

      def es_type
        'wiki_blob'
      end

      def elastic_search_as_wiki_page(*args, **kwargs)
        elastic_search_as_found_blob(*args, **kwargs).map! do |blob|
          Gitlab::Search::FoundWikiPage.new(blob)
        end
      end

      # Disable the routing for group level search
      # Will be enabled from MR: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125137
      def routing_options(options)
        return {} if options[:group_ids].present?

        super
      end
    end
  end
end
