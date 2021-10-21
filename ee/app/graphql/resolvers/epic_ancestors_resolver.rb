# frozen_string_literal: true

module Resolvers
  class EpicAncestorsResolver < EpicsResolver
    type Types::EpicType, null: true

    argument :include_ancestor_groups, GraphQL::Types::Boolean,
             required: false,
             description: 'Include epics from ancestor groups.',
             default_value: true

    def resolve_with_lookahead(**args)
      items = super

      offset_pagination(items)
    end

    private

    def relative_param
      return {} unless parent

      { child_id: parent.id, hierarchy_order: :desc }
    end
  end
end
