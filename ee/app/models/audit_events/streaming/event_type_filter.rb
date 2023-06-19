# frozen_string_literal: true

module AuditEvents
  module Streaming
    class EventTypeFilter < ApplicationRecord
      include StreamableEventTypeFilter

      self.table_name = 'audit_events_streaming_event_type_filters'

      belongs_to :external_audit_event_destination

      validates :audit_event_type,
        presence: true,
        length: { maximum: 255 },
        uniqueness: { scope: :external_audit_event_destination_id }
    end
  end
end
