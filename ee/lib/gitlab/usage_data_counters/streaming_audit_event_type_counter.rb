# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class StreamingAuditEventTypeCounter < BaseCounter
      KNOWN_EVENTS = Gitlab::Audit::Type::Definition.event_names
      PREFIX = 'audit_events'
    end
  end
end
