# frozen_string_literal: true

module Resolvers
  class EpicAncestorsResolver < EpicsResolver
    type Types::EpicType, null: true

    argument :include_ancestor_groups, GraphQL::Types::Boolean,
             required: false,
             description: 'Include epics from ancestor groups.',
             default_value: true

    # EpicResolver defines parent method to get the "parent" object which used the resolver,
    # which for epic's ancestors is always the epic for which we want to get list of ancestors
    alias_method :epic, :parent

    private

    def find_epics(args)
      items = apply_lookahead(::Epics::CrossHierarchyAncestorsFinder.new(context[:current_user], args).execute)
      accessible_ancestors(items).reverse!
    end

    def relative_param
      { child: epic }
    end

    def accessible_ancestors(ancestors)
      # Ancestors are sorted in ascending order, but inaccessible ancestors are filtered out by finder.
      # Iterate from closest ancestor until root or first missing ancestor
      previous_ancestor = epic
      ancestors.take_while do |ancestor|
        is_direct_parent = previous_ancestor.parent_id == ancestor.id
        previous_ancestor = ancestor

        is_direct_parent
      end
    end
  end
end
