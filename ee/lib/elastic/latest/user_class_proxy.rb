# frozen_string_literal: true

module Elastic
  module Latest
    class UserClassProxy < ApplicationClassProxy
      FUZZY_SEARCH_FIELDS = %w[name username email public_email].freeze

      def elastic_search(query, fuzzy_search_fields: FUZZY_SEARCH_FIELDS, options: {})
        query_hash = {}
        musts = []
        filters = []

        if options[:count_only]
          filters = fuzzy_query(filters: filters, query: query, search_fields: fuzzy_search_fields, options: options)
          query_hash[:size] = 0
        else
          musts = fuzzy_query(filters: musts, query: query, search_fields: fuzzy_search_fields, options: options)
        end

        filters = ancestry_query(filters, options)
        filters = forbidden_states_filter(filters, options)

        query_hash[:query] = {
          bool: {
            must: musts,
            filter: filters
          }
        }

        query_hash = apply_sort(query_hash, options)

        search(query_hash, options)
      end

      def fuzzy_query(filters:, query:, search_fields:, options: {})
        return filters unless query

        search_fields -= ['email'] unless admin(options)
        shoulds = []

        search_fields.each do |field|
          shoulds << {
            fuzzy: {
              "#{field}": {
                value: query,
                _name: "search:query:fuzzy:#{field}"
              }
            }
          }
        end

        filters << context.name(:fuzzy_search) do
          {
            bool: {
              should: shoulds
            }
          }
        end
      end

      def ancestry_query(filters, options)
        current_user = options[:current_user]
        projects = options[:projects]
        groups = options[:groups]

        return filters unless current_user
        return filters unless projects || groups

        namespace_ancestry_ids = []
        namespace_ancestry_ids << project_namespace_ids(projects) if projects
        namespace_ancestry_ids << group_namespace_ids(groups) if groups

        filters << context.name(:namespace) do
          ancestry_filter(current_user, namespace_ancestry_ids.flatten)
        end
      end

      def forbidden_states_filter(filters, options)
        return filters if admin(options)

        filters << {
          term: {
            in_forbidden_state: false
          }
        }
      end

      private

      def project_namespace_ids(projects)
        projects.map(&:elastic_namespace_ancestry)
      end

      def group_namespace_ids(groups)
        groups.map(&:elastic_namespace_ancestry)
      end

      def admin(options)
        options[:admin] == true
      end
    end
  end
end
