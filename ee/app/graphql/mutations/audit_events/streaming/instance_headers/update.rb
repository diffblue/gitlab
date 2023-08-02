# frozen_string_literal: true

module Mutations
  module AuditEvents
    module Streaming
      module InstanceHeaders
        class Update < Base
          graphql_name 'AuditEventsStreamingInstanceHeadersUpdate'

          argument :header_id, ::Types::GlobalIDType[::AuditEvents::Streaming::InstanceHeader],
            required: true,
            description: 'Header to update.'

          argument :key, GraphQL::Types::String,
            required: true,
            description: 'Header key.'

          argument :value, GraphQL::Types::String,
            required: true,
            description: 'Header value.'

          field :header, ::Types::AuditEvents::Streaming::InstanceHeaderType,
            null: true,
            description: 'Updates header.'

          def resolve(header_id:, key:, value:)
            header = find_header(header_id)

            response = ::AuditEvents::Streaming::InstanceHeaders::UpdateService.new(
              params: { header: header, key: key, value: value },
              current_user: current_user
            ).execute

            if response.success?
              { header: response.payload[:header], errors: [] }
            elsif header.present?
              { header: header.reset, errors: response.errors }
            end
          end
        end
      end
    end
  end
end
