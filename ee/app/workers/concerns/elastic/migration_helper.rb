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
      document_type.to_s.pluralize
    end

    def get_number_of_shards(index_name: new_index_name)
      helper.get_settings(index_name: index_name).dig('number_of_shards').to_i
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
      helper.refresh_index(index_name: new_index_name)
      helper.documents_count(index_name: new_index_name)
    end

    def reindexing_cleanup!
      helper.delete_index(index_name: new_index_name) if helper.index_exists?(index_name: new_index_name)
    end

    def reindex(slice:, max_slices:, script: nil)
      body = reindex_query(slice: slice, max_slices: max_slices, script: script)

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

    def reindex_query(slice:, max_slices:, script: nil)
      query = {
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

      if script
        query[:script] = {
          lang: 'painless',
          source: script
        }
      end

      query
    end

    def create_index_for_first_batch!(target_classes)
      return if migration_state[:slice].present?

      reindexing_cleanup! # support retries

      log "Change index settings for #{document_type_plural} index under #{new_index_name}"

      default_setting = Elastic::IndexSetting.default
      Elastic::IndexSetting[new_index_name].update!(number_of_replicas: default_setting.number_of_replicas,
        number_of_shards: default_setting.number_of_shards)

      log "Create standalone #{document_type_plural} index under #{new_index_name}"

      helper.create_standalone_indices(target_classes: target_classes)
    end
  end
end
