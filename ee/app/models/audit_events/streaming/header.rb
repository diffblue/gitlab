# frozen_string_literal: true

module AuditEvents
  module Streaming
    class Header < ApplicationRecord
      include StreamableHeader

      self.table_name = 'audit_events_streaming_headers'

      validates :key,
        presence: true,
        length: { maximum: 255 },
        uniqueness: { scope: :external_audit_event_destination_id }

      belongs_to :external_audit_event_destination
    end
  end
end
