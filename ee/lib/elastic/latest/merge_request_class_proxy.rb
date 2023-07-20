# frozen_string_literal: true

module Elastic
  module Latest
    class MergeRequestClassProxy < ApplicationClassProxy
      extend ::Gitlab::Utils::Override
      include StateFilter

      def elastic_search(query, options: {})
        options[:features] = 'merge_requests'
        options[:no_join_project] = true

        query_hash =
          if query =~ /\!(\d+)\z/
            iid_query_hash(Regexp.last_match(1))
          else
            # iid field can be added here as lenient option will
            # pardon format errors, like integer out of range.
            fields = %w[iid^3 title^2 description]

            basic_query_hash(fields, query, options)
          end

        context.name(:merge_request) do
          query_hash = context.name(:authorized) { project_ids_filter(query_hash, options) }
          query_hash = context.name(:match) { state_filter(query_hash, options) }
          query_hash = context.name(:archived) { archived_filter(query_hash) } if archived_filter_applicable?(options)
          if hidden_filter_applicable?(options[:current_user])
            query_hash = context.name(:hidden) { hidden_filter(query_hash) }
          end
        end
        query_hash = apply_sort(query_hash, options)

        search(query_hash, options)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def preload_indexing_data(relation)
        relation.includes(:author, target_project: [:project_feature, :namespace])
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      # Builds an elasticsearch query that will select documents from a
      # set of projects for Group and Project searches, taking user access
      # rules for merge_requests into account. Relies upon super for Global searches
      override :project_ids_filter
      def project_ids_filter(query_hash, options)
        return super if options[:public_and_internal_projects]

        current_user = options[:current_user]
        scoped_project_ids = scoped_project_ids(current_user, options[:project_ids])
        return super if scoped_project_ids == :any

        context.name(:project) do
          query_hash[:query][:bool][:filter] ||= []
          query_hash[:query][:bool][:filter] << {
            terms: {
              _name: context.name,
              target_project_id: filter_ids_by_feature(scoped_project_ids, current_user, 'merge_requests')
            }
          }
        end

        query_hash
      end

      def hidden_filter_applicable?(user)
        Feature.enabled?(:hide_merge_requests_from_banned_users) && !user&.can_admin_all_resources?
      end

      def archived_filter_applicable?(options)
        Feature.enabled?(:search_merge_requests_hide_archived_projects) &&
          ::Elastic::DataMigrationService.migration_has_finished?(:backfill_archived_on_merge_requests) &&
          !options[:include_archived]
      end

      def hidden_filter(query_hash)
        if ::Elastic::DataMigrationService.migration_has_finished?(:backfill_hidden_on_merge_requests)
          query_hash[:query][:bool][:filter] << { term: { hidden: { _name: context.name(:non_hidden), value: false } } }
        end

        query_hash
      end
    end
  end
end
