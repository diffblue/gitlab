# frozen_string_literal: true

module Types
  module AuditEvents
    module ExternalAuditEventDestinationInterface
      include Types::BaseInterface

      field :id, GraphQL::Types::ID,
        null: false,
        description: 'ID of the destination.'

      field :destination_url, GraphQL::Types::String,
        null: false,
        description: 'External destination to send audit events to.'

      field :verification_token, GraphQL::Types::String,
        null: false,
        description: 'Verification token to validate source of event.'
    end
  end
end
