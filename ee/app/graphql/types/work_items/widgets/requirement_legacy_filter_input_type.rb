# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class RequirementLegacyFilterInputType < BaseInputObject
        graphql_name 'RequirementLegacyFilterInput'

        argument :legacy_iids, [GraphQL::Types::String],
                 required: true,
                 description: 'List of legacy requirement IIDs of work items. or example `["1", "2"]`.'
      end
    end
  end
end
