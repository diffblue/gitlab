# frozen_string_literal: true

module Types
  module AuditEvents
    module Streaming
      module BaseHeaderInterface
        include Types::BaseInterface

        field :id, GraphQL::Types::ID,
          null: false,
          description: 'ID of the header.'

        field :key, GraphQL::Types::String,
          null: false,
          description: 'Key of the header.'

        field :value, GraphQL::Types::String,
          null: false,
          description: 'Value of the header.'
      end
    end
  end
end
