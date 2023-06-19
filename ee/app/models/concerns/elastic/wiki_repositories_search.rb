# frozen_string_literal: true

module Elastic
  module WikiRepositoriesSearch
    extend ActiveSupport::Concern

    include ApplicationVersionedSearch

    delegate(:delete_index_for_commits_and_blobs, :elastic_search, to: :__elasticsearch__)

    def index_wiki_blobs
      ElasticWikiIndexerWorker.perform_async(container.id, container.class.name)
    end
  end
end
