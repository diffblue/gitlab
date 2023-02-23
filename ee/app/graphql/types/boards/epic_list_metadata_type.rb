# frozen_string_literal: true

module Types
  module Boards
    # rubocop: disable Graphql/AuthorizeTypes
    # the board is authorized in `EpicListType`

    class EpicListMetadataType < BaseObject
      graphql_name 'EpicListMetadata'
      description 'Represents epic board list metadata'

      field :epics_count, GraphQL::Types::Int, null: true,
                                               description: 'Count of epics in the list.'

      field :total_weight, GraphQL::Types::Int, null: true,
                                                description: 'Total weight of all issues in the list.',
                                                alpha: { milestone: '14.7' }
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
