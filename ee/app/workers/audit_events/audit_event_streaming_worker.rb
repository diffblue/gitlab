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
    data_consistency :sticky
    feature_category :audit_events

    def perform(audit_operation, audit_event_id, audit_event_json = nil)
      raise ArgumentError, 'audit_event_id and audit_event_json cannot be passed together' if audit_event_id.present? && audit_event_json.present?

      audit_event = audit_event(audit_event_id, audit_event_json)
      return if audit_event.nil?

      group = audit_event.root_group_entity
      return if group.nil? # Do nothing if the event can't be resolved to a single group.
      return unless group.licensed_feature_available?(:external_audit_events)

      group.external_audit_event_destinations.each do |destination|
        next unless allowed_to_stream?(destination, audit_operation)

        headers = destination.headers_hash
        headers[EVENT_TYPE_HEADER_KEY] = audit_operation if audit_operation.present?

        track_audit_event_count(audit_operation)

        Gitlab::HTTP.post(
          destination.destination_url,
          body: request_body(audit_event, audit_operation),
          headers: headers
        )
      rescue URI::InvalidURIError => e
        Gitlab::ErrorTracking.log_exception(e)
      rescue *Gitlab::HTTP::HTTP_ERRORS
      end
    end

    private

    def track_audit_event_count(audit_operation)
      return unless Gitlab::UsageDataCounters::StreamingAuditEventTypeCounter::KNOWN_EVENTS.include? audit_operation

      Gitlab::UsageDataCounters::StreamingAuditEventTypeCounter.count(audit_operation)
    rescue Redis::CannotConnectError => e
      Gitlab::ErrorTracking.log_exception(e)
    end

    # TODO: Remove audit_operation.present? guard clause once we implement names for all the audit event types.
    # Epic: https://gitlab.com/groups/gitlab-org/-/epics/8497
    def allowed_to_stream?(destination, audit_operation)
      return true unless audit_operation.present?
      return true unless destination.event_type_filters.exists?

      destination.event_type_filters.audit_event_type_in(audit_operation).exists?
    end

    def request_body(audit_event, audit_operation)
      body = audit_event.as_json
      body[:event_type] = audit_operation
      # We want to have uuid for stream only audit events also and in this case audit_event's id is blank.
      # so we override it with `SecureRandom.uuid`
      body["id"] = SecureRandom.uuid if audit_event.id.blank?
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
      AuditEvent.new(audit_event_json)
    end
  end
end
