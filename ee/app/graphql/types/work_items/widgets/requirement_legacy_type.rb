# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # rubocop:disable Graphql/AuthorizeTypes
      class RequirementLegacyType < BaseObject
        graphql_name 'WorkItemWidgetRequirementLegacy'
        description 'Represents a legacy requirement widget'

        implements Types::WorkItems::WidgetInterface

        field :legacy_iid, GraphQL::Types::Int,
              deprecated: { reason: 'Use Work Item IID instead', milestone: '15.9' },
              null: true, description: 'Legacy requirement IID associated with the work item.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
