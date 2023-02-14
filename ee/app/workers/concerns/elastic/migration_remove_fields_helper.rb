# frozen_string_literal: true

module Elastic
  module MigrationRemoveFieldsHelper
    DEFAULT_BATCH_SIZE = 10_000

    def migrate
      log "Removing #{formatted_fields} from #{document_type} migration starting"

      if completed?
        log "Skipping migration since it is already applied"
        return
      end

      log "Removing #{formatted_fields} from #{document_type} documents for batch of #{batch_size} documents"

      update_by_query!
    end

    def update_by_query!
      response = client.update_by_query(
        index: index_name,
        max_docs: batch_size,
        body: {
          query: query,
          script: {
            lang: 'painless',
            source: script_to_remove_fields
          }
        }
      )

      log "#{response['updated']} updates were made"
    end

    def query
      {
        bool: {
          should: fields_exist_query,
          minimum_should_match: 1,
          filter: [
            {
              term: {
                type: document_type
              }
            }
          ]
        }
      }
    end

    def completed?
      log "completed check: Refreshing #{index_name}"
      helper.refresh_index(index_name: index_name)

      query = {
        size: 0,
        query: {
          term: {
            type: {
              value: document_type
            }
          }
        },
        aggs: {
          remaining: {
            filter: {
              bool: {
                should: fields_exist_query
              }
            }
          }
        }
      }

      results = client.search(index: index_name, body: query)
      doc_count = results.dig('aggregations', 'remaining', 'doc_count')
      log "Migration has #{doc_count} documents remaining" if doc_count

      doc_count && doc_count == 0
    end

    def index_name
      raise NotImplementedError
    end

    def document_type
      raise NotImplementedError
    end

    def field_to_remove
      raise NotImplementedError
    end

    def fields_to_remove
      Array.wrap(field_to_remove)
    end

    private

    def fields_exist_query
      fields_to_remove.map do |field|
        {
          exists: {
            field: field
          }
        }
      end
    end

    def script_to_remove_fields
      fields_to_remove.map { |field| "ctx._source.remove('#{field}');" }.join(' ')
    end

    def formatted_fields
      fields_to_remove.join(' and ')
    end

    def batch_size
      return self.class::BATCH_SIZE if self.class.const_defined?(:BATCH_SIZE)

      DEFAULT_BATCH_SIZE
    end
  end
end
