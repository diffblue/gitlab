# frozen_string_literal: true

module Elastic
  module MigrationHelper
    private

    def document_type
      raise NotImplementedError
    end

    def document_type_fields
      raise NotImplementedError
    end

    def document_type_plural
      document_type.pluralize
    end

    def get_number_of_shards
      helper.get_settings(index_name: new_index_name).dig('number_of_shards').to_i
    end

    def default_index_name
      helper.target_name
    end

    def new_index_name
      "#{default_index_name}-#{document_type_plural}"
    end

    def original_documents_count
      query = {
        size: 0,
        aggs: {
          documents: {
            filter: {
              term: {
                type: {
                  value: document_type
                }
              }
            }
          }
        }
      }

      results = client.search(index: default_index_name, body: query)
      results.dig('aggregations', 'documents', 'doc_count')
    end

    def new_documents_count
      helper.documents_count(index_name: new_index_name)
    end

    def reindexing_cleanup!
      helper.delete_index(index_name: new_index_name) if helper.index_exists?(index_name: new_index_name)
    end

    def reindex(slice:, max_slices:)
      body = reindex_query(slice: slice, max_slices: max_slices)

      response = client.reindex(body: body, wait_for_completion: false)

      response['task']
    end

    def reindexing_completed?(task_id:)
      response = helper.task_status(task_id: task_id)
      completed = response['completed']

      return false unless completed

      stats = response['response']
      if stats['failures'].present?
        log_raise "Reindexing failed with #{stats['failures']}"
      end

      if stats['total'] != (stats['updated'] + stats['created'] + stats['deleted'])
        log_raise "Slice reindexing seems to have failed, total is not equal to updated + created + deleted"
      end

      true
    end

    def reindex_query(slice:, max_slices:)
      {
        source: {
          index: default_index_name,
          _source: document_type_fields,
          query: {
            match: {
              type: document_type
            }
          },
          slice: {
            id: slice,
            max: max_slices
          }
        },
        dest: {
          index: new_index_name
        }
      }
    end
  end
end
