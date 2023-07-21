# frozen_string_literal: true

module Mutations
  module AuditEvents
    module Streaming
      module InstanceHeaders
        class Create < Base
          graphql_name 'AuditEventsStreamingInstanceHeadersCreate'

          argument :key, GraphQL::Types::String,
            required: true,
            description: 'Header key.'

          argument :value, GraphQL::Types::String,
            required: true,
            description: 'Header value.'

          argument :destination_id, ::Types::GlobalIDType[::AuditEvents::InstanceExternalAuditEventDestination],
            required: true,
            description: 'Instance level external destination to associate header with.'

          field :header, ::Types::AuditEvents::Streaming::InstanceHeaderType,
            null: true,
            description: 'Created header.'

          def resolve(destination_id:, key:, value:)
            response = ::AuditEvents::Streaming::InstanceHeaders::CreateService.new(
              params: { key: key, value: value, destination: find_destination(destination_id) },
              current_user: current_user
            ).execute

            if response.success?
              { header: response.payload[:header], errors: [] }
            else
              { header: nil, errors: response.errors }
            end
          end
        end
      end
    end
  end
end
