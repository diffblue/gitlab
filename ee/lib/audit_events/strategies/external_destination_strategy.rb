# frozen_string_literal: true

module AuditEvents
  module Strategies
    class ExternalDestinationStrategy
      attr_reader :audit_operation, :audit_event

      EVENT_TYPE_HEADER_KEY = "X-Gitlab-Audit-Event-Type"
      REQUEST_BODY_SIZE_LIMIT = 25.megabytes
      STREAMABLE_ERROR_MESSAGE = 'Subclasses must implement the `streamable?` method'
      DESTINATIONS_ERROR_MESSAGE = 'Subclasses must implement the `destinations` method'

      def initialize(audit_operation, audit_event)
        @audit_operation = audit_operation
        @audit_event = audit_event
      end

      def streamable?
        raise NotImplementedError, STREAMABLE_ERROR_MESSAGE
      end

      def execute
        return unless streamable?

        destinations.each do |destination|
          track_and_stream(destination) if destination.allowed_to_stream?(audit_operation)
        end
      end

      private

      def destinations
        raise NotImplementedError, DESTINATIONS_ERROR_MESSAGE
      end

      def track_and_stream(destination)
        headers = build_headers(destination)

        track_audit_event_count

        Gitlab::HTTP.post(
          destination.destination_url,
          body: request_body,
          headers: headers
        )
      rescue URI::InvalidURIError => e
        Gitlab::ErrorTracking.log_exception(e)
      rescue *Gitlab::HTTP::HTTP_ERRORS
      end

      def build_headers(destination)
        headers = destination.headers_hash
        headers[EVENT_TYPE_HEADER_KEY] = audit_operation if audit_operation.present?
        headers
      end

      def track_audit_event_count
        return unless Gitlab::UsageDataCounters::StreamingAuditEventTypeCounter::KNOWN_EVENTS.include? audit_operation

        Gitlab::UsageDataCounters::StreamingAuditEventTypeCounter.count(audit_operation)
      rescue Redis::CannotConnectError => e
        Gitlab::ErrorTracking.log_exception(e)
      end

      def request_body
        body = audit_event.as_json
        body[:event_type] = audit_operation
        # We want to have uuid for stream only audit events also and in this case audit_event's id is blank.
        # so we override it with `SecureRandom.uuid`
        body["id"] = SecureRandom.uuid if audit_event.id.blank?
        Gitlab::Json::LimitedEncoder.encode(body, limit: REQUEST_BODY_SIZE_LIMIT)
      end
    end
  end
end
