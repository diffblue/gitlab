# frozen_string_literal: true

module Elastic
  module MigrationBackfillHelper
    UPDATE_BATCH_SIZE = 100

    def migrate
      if completed?
        log "Skipping adding #{field_name} field to #{index_name} documents migration since it is already applied"
        return
      end

      log "Adding #{field_name} field to #{index_name} documents for batch of #{query_batch_size} documents"

      document_references = process_batch!

      log "Adding #{field_name} field to #{index_name} documents is completed for batch of #{document_references.size} documents"
    rescue StandardError => e
      log_raise "migrate failed with error: #{e.class}:#{e.message}"
    end

    def completed?
      helper.refresh_index(index_name: index_name)

      query = {
        size: 0,
        aggs: {
          documents: {
            filter: missing_field_filter
          }
        }
      }

      results = client.search(index: index_name, body: query)
      doc_count = results.dig('aggregations', 'documents', 'doc_count')

      log "Checking if there are documents without #{field_name} field: #{doc_count} documents left"

      doc_count == 0
    end

    private

    def index_name
      raise NotImplementedError
    end

    def field_name
      raise NotImplementedError
    end

    def missing_field_filter
      {
        bool: {
          must_not: {
            exists: {
              field: field_name
            }
          },
          must: {
            term: {
              type: {
                value: self.class::DOCUMENT_TYPE.es_type
              }
            }
          }
        }
      }
    end

    def process_batch!
      query = {
        size: query_batch_size,
        query: {
          bool: {
            filter: missing_field_filter
          }
        }
      }

      results = client.search(index: index_name, body: query)
      hits = results.dig('hits', 'hits') || []

      document_references = hits.map! do |hit|
        id = hit.dig('_source', 'id')
        es_id = hit['_id']

        # es_parent attribute is used for routing but is nil for some records, e.g., projects, users
        es_parent = hit['_routing']

        Gitlab::Elastic::DocumentReference.new(self.class::DOCUMENT_TYPE, id, es_id, es_parent)
      end

      document_references.each_slice(update_batch_size) do |refs|
        Elastic::ProcessInitialBookkeepingService.track!(*refs)
      end

      document_references
    end

    def query_batch_size
      return batch_size if respond_to?(:batch_size)

      raise NotImplemented
    end

    def update_batch_size
      return self.class::UPDATE_BATCH_SIZE if self.class.const_defined?(:UPDATE_BATCH_SIZE)

      UPDATE_BATCH_SIZE
    end
  end
end
