# frozen_string_literal: true

module Elastic
  module Latest
    module GitInstanceProxy
      extend ActiveSupport::Concern

      class_methods do
        def methods_for_all_write_targets
          super + [:delete_index_for_commits_and_blobs]
        end
      end

      def es_parent
        "project_#{project_id}"
      end

      def elastic_search(query, type: 'all', page: 1, per: 20, options: {})
        options = repository_specific_options(options)

        self.class.elastic_search(query, type: type, page: page, per: per, options: options)
      end

      # @return [Kaminari::PaginatableArray]
      def elastic_search_as_found_blob(query, page: 1, per: 20, options: {}, preload_method: nil)
        options = repository_specific_options(options)

        self.class.elastic_search_as_found_blob(query, page: page, per: per, options: options, preload_method: preload_method)
      end

      def blob_aggregations(query, options)
        self.class.blob_aggregations(query, repository_specific_options(options))
      end

      def delete_index_for_commits_and_blobs(wiki: false)
        types = wiki ? %w[wiki_blob] : %w[commit blob]
        if (wiki && ::Elastic::DataMigrationService.migration_has_finished?(:migrate_wikis_to_separate_index)) || types.include?('commit')
          index, rid = if wiki
                         [::Elastic::Latest::WikiConfig.index_name, "wiki_#{project_id}"]
                       else
                         [::Elastic::Latest::CommitConfig.index_name, project_id]
                       end

          response = client.delete_by_query(
            index: index,
            routing: es_parent,
            body: {
              query: {
                bool: {
                  filter: [
                    {
                      term: {
                        rid: rid
                      }
                    }
                  ]
                }
              }
            }
          )
          return response if wiki
        end

        client.delete_by_query(
          index: index_name,
          routing: es_parent,
          body: {
            query: {
              bool: {
                filter: [
                  {
                    terms: {
                      type: types
                    }
                  },
                  {
                    has_parent: {
                      parent_type: 'project',
                      query: {
                        term: {
                          id: project_id
                        }
                      }
                    }
                  }
                ]
              }
            }
          }
        )
      end

      private

      def repository_id
        raise NotImplementedError
      end

      def repository_specific_options(options)
        if options[:repository_id].nil?
          options = options.merge(repository_id: repository_id)
        end

        options
      end
    end
  end
end
