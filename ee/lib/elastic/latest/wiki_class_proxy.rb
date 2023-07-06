# frozen_string_literal: true

module Elastic
  module Latest
    class WikiClassProxy < ApplicationClassProxy
      include GitClassProxy

      def es_type
        'wiki_blob'
      end

      def elastic_search_as_wiki_page(*args, **kwargs)
        elastic_search_as_found_blob(*args, **kwargs).map! do |blob|
          Gitlab::Search::FoundWikiPage.new(blob)
        end
      end
    end
  end
end
