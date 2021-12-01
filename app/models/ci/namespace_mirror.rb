# frozen_string_literal: true

module Ci
  # This model represents a record in a shadow table of the main database's namespaces table.
  # It allows us to navigate the namespace hierarchy on the ci database without resorting to a JOIN.
  class NamespaceMirror < ApplicationRecord
    belongs_to :namespace

    scope :contains_namespaces, -> (ids) {
      where('traversal_ids @> ARRAY[?]::int[]', ids.join(','))
    }

    class << self
      def sync!(event)
        traversal_ids = event.namespace.self_and_ancestor_ids(hierarchy_order: :desc)

        upsert({ namespace_id: event.namespace_id, traversal_ids: traversal_ids },
               unique_by: :namespace_id)

        # TODO: after fully implemented `sync_traversal_ids` FF, we will not need this method.
        # However, we also need to change the PG trigger to reflect `namespaces.traversal_ids` changes
        sync_children_namespaces!(event.namespace_id, traversal_ids)
      end

      private

      def sync_children_namespaces!(namespace_id, traversal_ids)
        contains_namespaces([namespace_id])
          .where.not(namespace_id: namespace_id)
          .update_all(
            "traversal_ids = ARRAY[#{traversal_ids.join(',')}]::int[] || traversal_ids[array_position(traversal_ids, #{namespace_id}) + 1:]"
          )
      end
    end
  end
end
