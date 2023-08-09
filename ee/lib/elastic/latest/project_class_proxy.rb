# frozen_string_literal: true

module Elastic
  module Latest
    class ProjectClassProxy < ApplicationClassProxy
      def elastic_search(query, options: {})
        if ::Elastic::DataMigrationService.migration_has_finished?(:migrate_projects_to_separate_index)
          options[:project_id_field] = :id
          options[:no_join_project] = true
        end

        options[:in] = %w[name^10 name_with_namespace^2 path_with_namespace path^9 description]

        query_hash = basic_query_hash(options[:in], query, options)

        filters = [{ terms: { _name: context.name(:doc, :is_a, es_type), type: [es_type] } }]

        context.name(:project) do
          if options[:namespace_id]
            filters << {
              terms: {
                _name: context.name(:related, :namespaces),
                namespace_id: [options[:namespace_id]].flatten
              }
            }
          end

          if Feature.enabled?(:search_projects_hide_archived, options[:current_user]) && !options[:include_archived]
            filters << {
              terms: {
                _name: context.name(:archived, false),
                archived: [false]
              }
            }
          end

          if options[:visibility_levels]
            filters << {
              terms: {
                _name: context.name(:visibility_level),
                visibility_level: [options[:visibility_levels]].flatten
              }
            }
          end

          if options[:project_ids]
            filters << {
              bool: project_ids_query(options[:current_user], options[:project_ids], options[:public_and_internal_projects], no_join_project: options[:no_join_project], project_id_field: options[:project_id_field])
            }
          end

          query_hash[:query][:bool][:filter] ||= []
          query_hash[:query][:bool][:filter] += filters
        end

        search(query_hash, options)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def preload_indexing_data(relation)
        relation.includes(:project_feature, :route, :namespace, :catalog_resource)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
