# frozen_string_literal: true

module Elastic
  module MigrationBackfillHelper
    def migrate
      update_mapping!(index_name, { properties: new_mappings }) if respond_to?(:new_mappings)

      if completed?
        log "Skipping adding #{field_name} field to #{index_name} documents migration since it is already applied"
        return
      end

      log "Adding #{field_name} field to #{index_name} documents for batch of #{self.class::QUERY_BATCH_SIZE} documents"

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
          }
        }
      }
    end

    def process_batch!
      query = {
        size: self.class::QUERY_BATCH_SIZE,
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
        es_parent = "project_#{hit.dig('_source', 'project_id')}"

        Gitlab::Elastic::DocumentReference.new(self.class::DOCUMENT_TYPE, id, es_id, es_parent)
      end

      document_references.each_slice(self.class::UPDATE_BATCH_SIZE) do |refs|
        Elastic::ProcessInitialBookkeepingService.track!(*refs)
      end

      document_references
    end
  end
end
