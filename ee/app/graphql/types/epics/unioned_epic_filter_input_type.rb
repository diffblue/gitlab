# frozen_string_literal: true

module Types
  module Epics
    class UnionedEpicFilterInputType < BaseInputObject
      graphql_name 'UnionedEpicFilterInput'

      argument :label_name, [GraphQL::Types::String],
               required: false,
               description: 'Filters epics that have at least one of the given labels.'

      argument :author_username, [GraphQL::Types::String],
               required: false,
               description: 'Filters epics that are authored by one of the given users.'
    end
  end
end
