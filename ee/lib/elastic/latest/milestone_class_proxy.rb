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
        query_hash = context.name(:milestone, :related) { project_ids_filter(query_hash, options) }
        query_hash[:query][:bool][:filter] ||= []
        query_hash[:query][:bool][:filter] += type_filter
        search(query_hash, options)
      end
    end
  end
end
