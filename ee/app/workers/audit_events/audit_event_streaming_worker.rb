# frozen_string_literal: true

module AuditEvents
  class AuditEventStreamingWorker
    include ApplicationWorker

    EVENT_TYPE_HEADER_KEY = "X-Gitlab-Audit-Event-Type"
    REQUEST_BODY_SIZE_LIMIT = 25.megabytes

    # Audit Events contains a unique ID so the ingesting system should
    # attempt to deduplicate based on this to allow this job to be idempotent.
    idempotent!
    worker_has_external_dependencies!
    data_consistency :always
    feature_category :audit_events

    def perform(audit_operation, audit_event_id, audit_event_json = nil)
      raise ArgumentError, 'audit_event_id and audit_event_json cannot be passed together' if audit_event_id.present? && audit_event_json.present?

      audit_event = audit_event(audit_event_id, audit_event_json)
      return if audit_event.nil?

      group = audit_event.root_group_entity
      return if group.nil? # Do nothing if the event can't be resolved to a single group.
      return unless group.licensed_feature_available?(:external_audit_events)

      group.external_audit_event_destinations.each do |destination|
        headers = destination.headers_hash
        headers[EVENT_TYPE_HEADER_KEY] = audit_operation if audit_operation.present?

        Gitlab::HTTP.post(destination.destination_url,
                          body: request_body(audit_event, audit_operation),
                          headers: headers)
      rescue URI::InvalidURIError => e
        Gitlab::ErrorTracking.log_exception(e)
      rescue *Gitlab::HTTP::HTTP_ERRORS
      end
    end

    private

    def request_body(audit_event, audit_operation)
      body = audit_event.as_json
      body[:event_type] = audit_operation
      Gitlab::Json::LimitedEncoder.encode(body, limit: REQUEST_BODY_SIZE_LIMIT)
    end

    # Fetches audit event from database if audit_event_id is present
    # Or parses audit event json into instance of AuditEvent if audit_event_json is present
    def audit_event(audit_event_id, audit_event_json)
      return parse_audit_event_json(audit_event_json) if audit_event_json.present?

      AuditEvent.find(audit_event_id) if audit_event_id.present?
    end

    def parse_audit_event_json(audit_event_json)
      audit_event_json = Gitlab::Json.parse(audit_event_json).with_indifferent_access
      audit_event = AuditEvent.new(audit_event_json)
      # We want to have created_at as unique id for deduplication if audit_event id is not present
      audit_event.id = audit_event.created_at.to_i if audit_event.id.blank?
      audit_event
    end
  end
end
