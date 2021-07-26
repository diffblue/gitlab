# frozen_string_literal: true

module Types
  module AppSec
    module Fuzzing
      module API
        # rubocop: disable Graphql/AuthorizeTypes
        class ScanProfileType < BaseObject
          graphql_name 'ApiFuzzingScanProfile'
          description 'An API Fuzzing scan profile.'

          field :name, GraphQL::Types::String, null: true,
                description: 'The unique name of the profile.'

          field :description, GraphQL::Types::String, null: true,
                description: 'A short description of the profile.'

          field :yaml, GraphQL::Types::String, null: true,
                description: 'A syntax highlit HTML representation of the YAML.'
        end
        # rubocop: enable Graphql/AuthorizeTypes
      end
    end
  end
end
