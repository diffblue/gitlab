# frozen_string_literal: true

module Elastic
  module Latest
    class SnippetClassProxy < ApplicationClassProxy
      def elastic_search(query, options: {})
        query_hash = basic_query_hash(%w[title description], query)
        query_hash = context.name(:snippet, :authorized) { filter(query_hash, options) }

        search(query_hash, options)
      end

      def es_type
        target.base_class.name.underscore
      end

      private

      def filter(query_hash, options)
        user = options[:current_user]
        return query_hash if user&.can_read_all_resources?

        filter_conditions =
          filter_personal_snippets(user, options) +
          filter_project_snippets(user, options)

        # Match any of the filter conditions, in addition to the existing conditions
        query_hash[:query][:bool][:filter] << {
          bool: {
            _name: context.name,
            should: filter_conditions
          }
        }

        query_hash
      end

      def filter_personal_snippets(user, options)
        filter_conditions = []

        # Include accessible personal snippets
        filter_conditions << {
          bool: {
            _name: context.name(:personal),
            filter: [
              { terms: { visibility_level: Gitlab::VisibilityLevel.levels_for_user(user) } }
            ],
            must_not: { exists: { field: 'project_id' } }
          }
        }

        # Include authored personal snippets
        if user
          filter_conditions << {
            bool: {
              _name: context.name(:authored),
              filter: [
                { term: { author_id: { _name: context.name(:as_author), value: user.id } } }
              ],
              must_not: { exists: { field: 'project_id' } }
            }
          }
        end

        filter_conditions
      end

      def filter_project_snippets(user, options)
        return [] unless Ability.allowed?(user, :read_cross_project)

        filter_conditions = []

        # Include all project snippets for authorized projects
        if user
          project_ids = user
            .authorized_projects(Gitlab::Access::GUEST)
            .filter_by_feature_visibility(:snippets, user)
            .pluck_primary_key

          filter_conditions << {
            bool: {
              _name: context.name(:membership, :id),
              must: [
                { terms: { project_id: project_ids } }
              ]
            }
          }
        end

        filter_conditions
      end
    end
  end
end
