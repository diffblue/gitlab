# frozen_string_literal: true

module AuditEvents
  module Streaming
    class EventTypeFilter < ApplicationRecord
      self.table_name = 'audit_events_streaming_event_type_filters'

      belongs_to :external_audit_event_destination

      validates :audit_event_type,
        presence: true,
        length: { maximum: 255 },
        uniqueness: { scope: :external_audit_event_destination_id }

      scope :audit_event_type_in, ->(audit_event_types) { where(audit_event_type: audit_event_types) }

      def to_s
        audit_event_type
      end

      def self.pluck_audit_event_type
        pluck(:audit_event_type)
      end
    end
  end
end
