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
          filters = fuzzy_query(clauses: filters, query: query, search_fields: fuzzy_search_fields, options: options)
          filters = namespace_query(filters, options)
          query_hash[:size] = 0
        else
          musts = fuzzy_query(clauses: musts, query: query, search_fields: fuzzy_search_fields, options: options)
          musts = namespace_query(musts, options)
        end

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

      def fuzzy_query(clauses:, query:, search_fields:, options: {})
        return clauses unless query

        search_fields -= ['email'] unless is_admin?(options)
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

        clauses << context.name(:fuzzy_search) do
          {
            bool: {
              should: shoulds
            }
          }
        end
      end

      def forbidden_states_filter(filters, options)
        return filters if is_admin?(options)

        filters << {
          term: {
            in_forbidden_state: false
          }
        }
      end

      def namespace_query(clauses, options)
        return clauses unless options[:project_id].present? || options[:group_id].present?

        project = Project.find_by_id(options[:project_id])
        group = Group.find_by_id(options[:group_id])
        shoulds = []

        if project
          terms = namespace_ids(project.elastic_namespace_ancestry)
          shoulds << { terms: { namespace_ancestry_ids: terms } }
        elsif group
          ids = namespace_ids(group.elastic_namespace_ancestry)
          prefix = ids.pop
          terms = ids

          shoulds << { prefix: { namespace_ancestry_ids: { value: prefix } } }
          shoulds << { terms: { namespace_ancestry_ids: terms } } if terms.any?
        end

        clauses << context.name(:namespace_filter) do
          {
            bool: {
              should: shoulds
            }
          }
        end
      end

      private

      def namespace_ids(ids, separator = '-')
        ids = ids.split(separator)

        ids.map.with_index do |_, idx|
          ids.slice(0..idx).join(separator) + separator
        end
      end

      # rubocop:disable Naming/PredicateName
      def is_admin?(options)
        options[:admin] == true
      end
      # rubocop:enable Naming/PredicateName
    end
  end
end
