# frozen_string_literal: true

module Elastic
  module Latest
    class UserClassProxy < ApplicationClassProxy
      SEARCH_FIELDS = %w[name username email public_email].freeze

      def elastic_search(query, options: {})
        query_hash = if simple_query_string_syntax?(query)
                       basic_query_hash(valid_fields(options), query, options)
                     else
                       fuzzy_query_hash(valid_fields(options), query, options)
                     end

        filters = []
        filters = namespace_query(filters, options)
        filters = forbidden_states_filter(filters, options)

        query_hash[:query][:bool][:filter] ||= []
        query_hash[:query][:bool][:filter] += filters

        query_hash[:size] = 0 if options[:count_only]
        query_hash = apply_sort(query_hash, options)

        search(query_hash, options)
      end

      def fuzzy_query_hash(fields, query, options)
        shoulds = []
        clause = options[:count_only] ? :filter : :must

        fields.each do |field|
          shoulds << {
            match: {
              "#{field}": {
                query: query,
                fuzziness: 'AUTO',
                _name: "#{clause}:bool:should:fuzzy:#{field}"
              }
            }
          }
        end

        {
          query: {
            bool: {
              "#{clause}": [
                {
                  bool: {
                    should: shoulds
                  }
                }
              ]
            }
          }
        }
      end

      def forbidden_states_filter(filters, options)
        return filters if is_admin?(options)

        filters << {
          term: {
            in_forbidden_state: {
              value: false,
              _name: 'filter:not_forbidden_state'
            }
          }
        }
      end

      def namespace_query(filters, options)
        return filters unless options[:project_id].present? || options[:group_id].present?

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

        filters << {
          bool: {
            should: shoulds
          }
        }
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def preload_indexing_data(relation)
        relation.includes(:status, :user_preference, :user_detail, members: [source: :namespace])
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      def simple_query_string_syntax?(query)
        query.match?(/[+\-|*()~"]/)
      end

      def valid_fields(options)
        return SEARCH_FIELDS if is_admin?(options)

        # Searching by private email is only available to admins.
        # Non-admins can get results matching on public_email.
        SEARCH_FIELDS - ['email']
      end

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
