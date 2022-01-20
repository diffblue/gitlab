# frozen_string_literal: true

module EE
  module Types
    module AuditEvents
      class ExternalAuditEventDestinationType < ::Types::BaseObject
        graphql_name 'ExternalAuditEventDestination'
        description 'Represents an external resource to send audit events to'

        field :id, GraphQL::Types::ID,
              null: false,
              description: 'ID of the destination.'

        field :destination_url, GraphQL::Types::String,
              null: false,
              description: 'External destination to send audit events to.'

        field :group, ::Types::GroupType,
              null: false,
              description: 'Group the destination belongs to.'

        field :verification_token, GraphQL::Types::String,
              null: false,
              description: 'Verification token to validate source of event.'
      end
    end
  end
end
