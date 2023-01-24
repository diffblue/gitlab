# frozen_string_literal: true

module Types
  module Epics
    class UnionedEpicFilterInputType < BaseInputObject
      graphql_name 'UnionedEpicFilterInput'

      argument :label_name, [GraphQL::Types::String],
               required: false,
               description: 'Filters epics that have at least one of the given labels. ' \
                            'Ignored unless `or_issuable_queries` flag is enabled.'
    end
  end
end
