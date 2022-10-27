# frozen_string_literal: true

module Resolvers
  module Epics
    class ChildrenResolver < EpicsResolver
      type Types::EpicType, null: true

      argument :include_ancestor_groups, GraphQL::Types::Boolean,
               required: false,
               description: 'Include child epics from ancestor groups.',
               default_value: true

      def find_epics(args)
        return super unless cross_hierarchy_children_enabled?

        apply_lookahead(
          ::Epics::CrossHierarchyChildrenFinder.new(context[:current_user], args).execute
        )
      end

      private

      def relative_param
        return super unless cross_hierarchy_children_enabled?
        return {} unless parent

        { parent: parent }
      end

      def cross_hierarchy_children_enabled?
        ::Feature.enabled?(:child_epics_from_different_hierarchies, parent&.group)
      end
    end
  end
end
