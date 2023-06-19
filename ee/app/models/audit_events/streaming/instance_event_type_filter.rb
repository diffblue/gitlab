# frozen_string_literal: true

module AuditEvents
  module Streaming
    class InstanceEventTypeFilter < ApplicationRecord
      self.table_name = 'audit_events_streaming_instance_event_type_filters'

      include StreamableEventTypeFilter

      belongs_to :instance_external_audit_event_destination

      validates :audit_event_type,
        presence: true,
        length: { maximum: 255 },
        uniqueness: { scope: :instance_external_audit_event_destination_id }
    end
  end
end
