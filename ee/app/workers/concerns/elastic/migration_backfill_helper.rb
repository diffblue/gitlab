# frozen_string_literal: true

module Elastic
  module MigrationBackfillHelper
    UPDATE_BATCH_SIZE = 100

    def migrate
      if completed?
        log "Skipping migration since it is already applied", field_names: field_names, index_name: index_name

        return
      end

      log "Start backfilling fields", field_names: field_names, index_name: index_name, batch_size: query_batch_size

      document_references = process_batch!

      log "Backfilling batch has been processed", field_names: field_names, index_name: index_name, documents_count: document_references.size
    rescue StandardError => e
      log_raise "migrate failed with error: #{e.class}:#{e.message}"
    end

    def completed?
      doc_count = remaining_documents_count

      log "Checking the number of documents without fields", field_names: field_names, remaining_count: doc_count

      doc_count == 0
    end

    private

    def index_name
      raise NotImplementedError
    end

    def remaining_documents_count
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
      count = results.dig('aggregations', 'documents', 'doc_count')

      set_migration_state(remaining_count: count)

      count
    end

    def field_names
      Array.wrap(field_name)
    end

    def field_name
      raise NotImplementedError
    end

    def fields_exist_query
      field_names.map do |field|
        {
          bool: {
            must_not: {
              exists: {
                field: field
              }
            }
          }
        }
      end
    end

    def missing_field_filter
      {
        bool: {
          minimum_should_match: 1,
          should: fields_exist_query,
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
