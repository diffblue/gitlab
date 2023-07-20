# frozen_string_literal: true

module Elastic
  module Latest
    class WikiClassProxy < ApplicationClassProxy
      include Routing
      include GitClassProxy

      def es_type
        'wiki_blob'
      end

      def elastic_search_as_wiki_page(*args, **kwargs)
        elastic_search_as_found_blob(*args, **kwargs).map! do |blob|
          Gitlab::Search::FoundWikiPage.new(blob)
        end
      end

      def routing_options(options)
        return {} if routing_disabled?(options)

        ids = options[:root_ancestor_ids].presence || []
        routing = build_routing(ids, prefix: 'n')
        { routing: routing.presence }.compact
      end
    end
  end
end
