# frozen_string_literal: true

module AuditEvents
  class AuditEventStreamingWorker
    include ApplicationWorker

    HEADER_KEY = "X-Gitlab-Event-Streaming-Token"
    REQUEST_BODY_SIZE_LIMIT = 25.megabytes

    # Audit Events contains a unique ID so the ingesting system should
    # attempt to deduplicate based on this to allow this job to be idempotent.
    idempotent!
    worker_has_external_dependencies!
    data_consistency :always
    feature_category :audit_events

    def perform(audit_event_id)
      audit_event = AuditEvent.find(audit_event_id)

      return if audit_event.entity.nil?

      group = group_entity(audit_event)

      return if group.nil? # Do nothing if the event can't be resolved to a single group.
      return unless group.licensed_feature_available?(:external_audit_events)

      group.external_audit_event_destinations.each do |destination|
        Gitlab::HTTP.post(destination.destination_url,
                          body: Gitlab::Json::LimitedEncoder.encode(audit_event.as_json, limit: REQUEST_BODY_SIZE_LIMIT),
                          use_read_total_timeout: true,
                          headers: { HEADER_KEY => destination.verification_token })
      rescue URI::InvalidURIError => e
        Gitlab::ErrorTracking.log_exception(e)
      rescue *Gitlab::HTTP::HTTP_ERRORS
      end
    end

    private

    def group_entity(audit_event)
      case audit_event.entity_type
      when 'Group'
        audit_event.entity
      when 'Project'
        # Project events should be sent to the root ancestor's streaming destinations
        # Projects without a group root ancestor should be ignored.
        audit_event.entity.group&.root_ancestor
      else
        nil
      end
    end
  end
end
