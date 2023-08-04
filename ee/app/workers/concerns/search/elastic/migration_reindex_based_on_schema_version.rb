# frozen_string_literal: true

# This helper is used to reindex the full index based on schema_version value
# The index should have schema_version in the mapping

module Search
  module Elastic
    module MigrationReindexBasedOnSchemaVersion
      UPDATE_BATCH_SIZE = 100

      def migrate
        if completed?
          log 'Skipping migration since it is already applied', index_name: index_name

          return
        end

        log 'Start reindexing', index_name: index_name, batch_size: query_batch_size

        document_references = process_batch!

        log 'Reindexing batch has been processed', index_name: index_name, documents_count: document_references.size
      rescue StandardError => e
        log_raise 'migrate failed', error_class: e.class, error_mesage: e.message
      end

      def completed?
        doc_count = remaining_documents_count

        log 'Checking the number of documents left with old schema_version', remaining_count: doc_count

        doc_count == 0
      end

      private

      def index_name
        self.class::DOCUMENT_TYPE.__elasticsearch__.index_name
      end

      def remaining_documents_count
        helper.refresh_index(index_name: index_name)
        count = client.count(index: index_name, body: query_with_old_schema_version)['count']
        set_migration_state(remaining_count: count)
        count
      end

      def query_with_old_schema_version
        {
          query: {
            bool: {
              minimum_should_match: 1,
              should: [
                { range: { schema_version: { lt: self.class::NEW_SCHEMA_VERSION } } },
                { bool: { must_not: { exists: { field: 'schema_version' } } } }
              ],
              filter: { term: { type: self.class::DOCUMENT_TYPE.es_type } }
            }
          }
        }
      end

      def process_batch!
        results = client.search(index: index_name, body: query_with_old_schema_version.merge(size: query_batch_size))
        hits = results.dig('hits', 'hits') || []
        document_references = hits.map! do |hit|
          id = hit.dig('_source', 'id')
          es_id = hit['_id']

          # es_parent attribute is used for routing but is nil for some records, e.g., projects, users
          es_parent = hit['_routing']

          Gitlab::Elastic::DocumentReference.new(self.class::DOCUMENT_TYPE, id, es_id, es_parent)
        end

        document_references.each_slice(update_batch_size) do |refs|
          ::Elastic::ProcessInitialBookkeepingService.track!(*refs)
        end

        document_references
      end

      def query_batch_size
        return batch_size if respond_to?(:batch_size)

        raise NotImplementedError
      end

      def update_batch_size
        self.class.const_defined?(:UPDATE_BATCH_SIZE) ? self.class::UPDATE_BATCH_SIZE : UPDATE_BATCH_SIZE
      end
    end
  end
end
