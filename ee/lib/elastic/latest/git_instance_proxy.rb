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

      def es_parent(is_wiki = false)
        return "project_#{project_id}" unless is_wiki
        return unless ::Elastic::DataMigrationService.migration_has_finished?(:reindex_wikis_to_fix_routing)

        "n_#{project ? project.root_ancestor.id : group.root_ancestor.id}"
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

      # If is_wiki is true and migrate_wikis_to_separate_index is finished then set
      # index as (#{env}-wikis)
      # rid as (wiki_project_#{id}) for ProjectWiki and (wiki_group_#{id}) for GroupWiki
      # If add_suffix_project_in_wiki_rid has not finished then rid might not have prefix(project/group) then
      # run delete_query_by_rid with sending rid as 'wiki_#{project_id}'
      def delete_index_for_commits_and_blobs(is_wiki: false)
        types = is_wiki ? %w[wiki_blob] : %w[commit blob]

        if (is_wiki && ::Elastic::DataMigrationService.migration_has_finished?(:migrate_wikis_to_separate_index)) || types.include?('commit')
          index, rid = if is_wiki
                         [::Elastic::Latest::WikiConfig.index_name, wiki_rid]
                       else
                         [::Elastic::Latest::CommitConfig.index_name, project_id]
                       end

          response = delete_query_by_rid(index, rid, is_wiki)
          # Consider to delete wikis by older rid(without suffix _project) as well
          if is_wiki && project_id && !::Elastic::DataMigrationService.migration_has_finished?(:add_suffix_project_in_wiki_rid)
            response = delete_query_by_rid(index, "wiki_#{project_id}", is_wiki)
          end

          return response if is_wiki # if condition can be removed once the blob gets migrated to the separate index
        end

        client.delete_by_query(
          index: index_name,
          routing: es_parent,
          conflicts: 'proceed',
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
                    term: {
                      project_id: project_id
                    }
                  }
                ]
              }
            }
          }
        )

        return if ::Elastic::DataMigrationService.migration_has_finished?(:migrate_projects_to_separate_index)

        # This delete_by_query can be removed completely once the blob gets migrated to the separate index
        client.delete_by_query(
          index: index_name,
          routing: es_parent,
          conflicts: 'proceed',
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

      def wiki_rid
        project ? "wiki_project_#{project_id}" : "wiki_group_#{group_id}"
      end

      def repository_id
        raise NotImplementedError
      end

      def repository_specific_options(options)
        if options[:repository_id].nil?
          options = options.merge(repository_id: repository_id)
        end

        options
      end

      def delete_query_by_rid(index, rid, is_wiki)
        client.delete_by_query(
          {
            index: index,
            routing: es_parent(is_wiki),
            conflicts: 'proceed',
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
          }.compact
        )
      end
    end
  end
end
