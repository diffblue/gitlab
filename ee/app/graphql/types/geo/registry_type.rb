# frozen_string_literal: true

module Types
  module Geo
    module RegistryType
      extend ActiveSupport::Concern

      included do
        authorize :read_geo_registry

        field :id, GraphQL::Types::ID, null: false, description: "ID of the #{graphql_name}"
        field :state, Types::Geo::RegistryStateEnum, null: true, method: :state_name, description: "Sync state of the #{graphql_name}"
        field :retry_count, GraphQL::Types::Int, null: true, description: "Number of consecutive failed sync attempts of the #{graphql_name}"
        field :last_sync_failure, GraphQL::Types::String, null: true, description: "Error message during sync of the #{graphql_name}"
        field :retry_at, Types::TimeType, null: true, description: "Timestamp after which the #{graphql_name} is resynced"
        field :last_synced_at, Types::TimeType, null: true, description: "Timestamp of the most recent successful sync of the #{graphql_name}"
        field :verified_at, Types::TimeType, null: true, description: "Timestamp of the most recent successful verification of the #{graphql_name}"
        field :verification_retry_at, Types::TimeType, null: true, description: "Timestamp after which the #{graphql_name} is reverified"
        field :created_at, Types::TimeType, null: true, description: "Timestamp when the #{graphql_name} was created"
      end
    end
  end
end
