# frozen_string_literal: true

module AuditEvents
  module Streaming
    class Header < ApplicationRecord
      self.table_name = 'audit_events_streaming_headers'

      validates :key,
        presence: true,
        length: { maximum: 255 },
        uniqueness: { scope: :external_audit_event_destination_id }
      validates :value, presence: true, length: { maximum: 255 }

      belongs_to :external_audit_event_destination

      def to_hash
        { key => value }
      end
    end
  end
end
