# frozen_string_literal: true

module AuditEvents
  module Streaming
    class InstanceHeader < ApplicationRecord
      include StreamableHeader

      self.table_name = 'instance_audit_events_streaming_headers'

      validates :key,
        presence: true,
        length: { maximum: 255 },
        uniqueness: { scope: :instance_external_audit_event_destination_id }

      belongs_to :instance_external_audit_event_destination
    end
  end
end
