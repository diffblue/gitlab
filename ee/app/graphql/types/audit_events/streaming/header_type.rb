# frozen_string_literal: true

# Headers are only available through destinations
# which are already authorized.
module Types
  module AuditEvents
    module Streaming
      class HeaderType < ::Types::BaseObject
        graphql_name 'AuditEventStreamingHeader'

        description 'Represents a HTTP header key/value that belongs to an audit streaming destination.'

        authorize :admin_external_audit_events

        implements BaseHeaderInterface
      end
    end
  end
end
