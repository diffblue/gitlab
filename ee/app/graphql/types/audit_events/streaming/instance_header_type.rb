# frozen_string_literal: true

module Types
  module AuditEvents
    module Streaming
      class InstanceHeaderType < ::Types::BaseObject
        graphql_name 'AuditEventsStreamingInstanceHeader'

        description 'Represents a HTTP header key/value that belongs to an instance level audit streaming destination.'

        authorize :admin_instance_external_audit_events

        implements BaseHeaderInterface
      end
    end
  end
end
