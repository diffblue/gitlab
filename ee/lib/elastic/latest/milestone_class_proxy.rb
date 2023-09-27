# frozen_string_literal: true

module Elastic
  module Latest
    class MilestoneClassProxy < ApplicationClassProxy
      def elastic_search(query, options: {})
        options[:in] = %w[title^2 description]
        options[:no_join_project] = ::Elastic::DataMigrationService.migration_has_finished?(
          :backfill_milestone_permissions_to_milestone_documents
        )
        query_hash = basic_query_hash(options[:in], query, options)
        type_filter = [{ terms: { _name: context.name(:doc, :is_a, es_type), type: [es_type] } }]
        context.name(:milestone) do
          query_hash = context.name(:related) { project_ids_filter(query_hash, options) }
          query_hash = context.name(:archived) { archived_filter(query_hash) } if archived_filter_applicable?(options)
        end
        query_hash[:query][:bool][:filter] ||= []
        query_hash[:query][:bool][:filter] += type_filter
        search(query_hash, options)
      end

      def preload_indexing_data(relation)
        relation.preload_for_indexing
      end

      private

      def archived_filter_applicable?(options)
        !(options[:include_archived] || options[:search_scope] == 'project') &&
          Feature.enabled?(:search_milestones_hide_archived_projects, options[:current_user]) &&
          ::Elastic::DataMigrationService.migration_has_finished?(:backfill_archived_on_milestones)
      end
    end
  end
end
