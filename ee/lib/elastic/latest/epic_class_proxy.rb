# frozen_string_literal: true

module Elastic
  module Latest
    class EpicClassProxy < ApplicationClassProxy
      include Elastic::Latest::Routing

      attr_reader :group, :current_user, :options

      def elastic_search(query, options: {})
        @group = find_group_by_id(options)
        @current_user = options[:current_user]
        @options = options

        query_hash = if allowed?
                       traversal_id = group.elastic_namespace_ancestry
                       query_hash = basic_query_hash(%w[title^2 description], query, options)
                       query_hash = traversal_ids_ancestry_filter(query_hash, [traversal_id], options)
                       query_hash = groups_filter(query_hash)
                       apply_sort(query_hash, options)
                     else
                       match_none
                     end

        search(query_hash, options)
      end

      def find_group_by_id(options)
        group_id = options[:group_ids]&.first
        Group.find_by_id(group_id)
      end

      def group_and_descendants
        @group_and_descendants ||= group.self_and_descendants
      end

      def allowed?
        return false unless group

        Ability.allowed?(current_user, :read_epic, group)
      end

      def match_none
        {
          query: { match_none: {} },
          size: 0
        }
      end

      def groups_filter(query_hash)
        # If a user is a member of a group, they also inherit access to all subgroups,
        # so here we check if user is member of the current group by checking :read_confidential_epic.
        # If that's the case we don't need further filtering.
        return query_hash if Ability.allowed?(current_user, :read_confidential_epic, group)

        # Filter for non-confidential epics OR confidential epics in subgroups having access to :read_confidential_epic.
        shoulds = [{ term: { confidential: { value: false, _name: 'confidential:false' } } }]

        group_ids = groups_can_read_confidential_epics.map(&:id)

        if group_ids.any?
          shoulds << {
            bool: {
              filter: [
                {
                  term: { confidential: { value: true, _name: 'confidential:true' } }
                },
                {
                  terms: { group_id: group_ids, _name: 'groups:can:read_confidential_epics' }
                }
              ]
            }
          }
        end

        query_hash[:query][:bool][:filter] << { bool: { should: shoulds } }

        query_hash
      end

      def groups_can_read_confidential_epics
        Group.groups_user_can(group_and_descendants, current_user, :read_confidential_epic)
      end

      def routing_options(options)
        group = find_group_by_id(options)

        return {} unless group

        root_namespace_id = group.root_ancestor.id

        { routing: "group_#{root_namespace_id}" }
      end

      def preload_indexing_data(relation)
        # rubocop: disable CodeReuse/ActiveRecord
        relation.includes(
          :author,
          :labels,
          :group,
          :start_date_sourcing_epic,
          :due_date_sourcing_epic,
          :start_date_sourcing_milestone,
          :due_date_sourcing_milestone
        )
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
