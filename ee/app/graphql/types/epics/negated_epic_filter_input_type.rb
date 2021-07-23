# frozen_string_literal: true

module Types
  module Epics
    class NegatedEpicFilterInputType < BaseInputObject
      argument :label_name, [GraphQL::Types::String, null: true],
               required: false,
               description: 'Filter by label name.'

      argument :author_username, GraphQL::Types::String,
               required: false,
               description: 'Filter by author username.'

      argument :my_reaction_emoji, GraphQL::Types::String,
               required: false,
               description: 'Filter by reaction emoji applied by the current user.'
    end
  end
end
