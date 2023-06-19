# frozen_string_literal: true

module AuditEvents
  module Streaming
    module StreamableEventTypeFilter
      extend ActiveSupport::Concern

      included do
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
end
