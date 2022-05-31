# frozen_string_literal: true

module AuditEvents
  class AuditEventStreamingWorker
    include ApplicationWorker

    STREAMING_TOKEN_HEADER_KEY = "X-Gitlab-Event-Streaming-Token"
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

      group = group_entity(audit_event)
      return if group.nil? # Do nothing if the event can't be resolved to a single group.
      return unless group.licensed_feature_available?(:external_audit_events)

      group.external_audit_event_destinations.each do |destination|
        headers = { STREAMING_TOKEN_HEADER_KEY => destination.verification_token }
        headers[EVENT_TYPE_HEADER_KEY] = audit_operation if audit_operation.present?

        Gitlab::HTTP.post(destination.destination_url,
                          body: request_body(audit_event, audit_operation),
                          use_read_total_timeout: true,
                          headers: headers)
      rescue URI::InvalidURIError => e
        Gitlab::ErrorTracking.log_exception(e)
      rescue *Gitlab::HTTP::HTTP_ERRORS
      end

    rescue ActiveRecord::RecordNotFound => e
      # TODO: Remove this temporary rescue block. Issue - https://gitlab.com/gitlab-org/gitlab/-/issues/361931
      # These jobs were queued with old args i.e. [audit_event_id, audit_event_json] i.e. before
      # the MR was deployed https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86881. This MR didn't follow the
      # correct sidekiq guidelines for adding a new argument to the worker. This led to inconsistencies and thus
      # the new code maps these args incorrectly as:
      # Actual args      -> Args received in the new worker code.
      # audit_event_id   -> audit_operation
      # audit_event_json -> audit_event_id
      # N/A              -> audit_event_json
      # The above incorrect mapping leads to ActiveRecord::RecordNotFound as the worker tries to find an AuditEvent
      # with id = audit_event_json.

      # Don't re-enqueue the job for genuine errors that are not related to the incompatibility issue
      return if audit_event_id.instance_of?(Integer)

      Gitlab::ErrorTracking.track_exception(e)
      # setting audit_operation as nil since we don't have that information.
      AuditEvents::AuditEventStreamingWorker.perform_async(nil, audit_operation, audit_event_id)
    end

    private

    def request_body(audit_event, audit_operation)
      body = audit_event.as_json
      body[:event_type] = audit_operation if audit_operation.present?
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

    def group_entity(audit_event)
      entity = audit_event.entity
      return if entity.nil?

      case audit_event.entity_type
      when 'Group'
        entity
      when 'Project'
        # Project events should be sent to the root ancestor's streaming destinations
        # Projects without a group root ancestor should be ignored.
        entity.group&.root_ancestor
      else
        nil
      end
    end
  end
end
