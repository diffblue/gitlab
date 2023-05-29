# frozen_string_literal: true

module AuditEvents
  class AuditEventStreamingWorker
    include ApplicationWorker

    # Audit Events contains a unique ID so the ingesting system should
    # attempt to deduplicate based on this to allow this job to be idempotent.
    idempotent!
    worker_has_external_dependencies!
    data_consistency :sticky
    feature_category :audit_events

    def perform(audit_operation, audit_event_id, audit_event_json = nil)
      raise ArgumentError, 'audit_event_id and audit_event_json cannot be passed together' if audit_event_id.present? && audit_event_json.present?

      audit_event = audit_event(audit_event_id, audit_event_json)
      return if audit_event.nil?

      AuditEvents::ExternalDestinationStreamer.new(audit_operation, audit_event).stream_to_destinations
    end

    private

    # Fetches audit event from database if audit_event_id is present
    # Or parses audit event json into instance of AuditEvent if audit_event_json is present
    def audit_event(audit_event_id, audit_event_json)
      return parse_audit_event_json(audit_event_json) if audit_event_json.present?

      AuditEvent.find(audit_event_id) if audit_event_id.present?
    end

    def parse_audit_event_json(audit_event_json)
      audit_event_json = Gitlab::Json.parse(audit_event_json).with_indifferent_access
      AuditEvent.new(audit_event_json)
    end
  end
end
