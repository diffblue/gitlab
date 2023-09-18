# frozen_string_literal: true

module AuditEvents
  module Strategies
    class BaseGoogleCloudLoggingDestinationStrategy < ExternalDestinationStrategy
      def initialize(audit_operation, audit_event)
        @logger = GoogleCloud::LoggingService::Logger.new

        super(audit_operation, audit_event)
      end

      private

      def track_and_stream(destination)
        track_audit_event_count

        @logger.log(destination.client_email, destination.private_key, json_payload(destination))
      end

      def json_payload(destination)
        { 'entries' => [log_entry(destination)] }.to_json
      end

      def log_entry(destination)
        {
          'logName' => destination.full_log_path,
          'resource' => {
            'type' => 'global'
          },
          'severity' => 'INFO',
          'jsonPayload' => ::Gitlab::Json.parse(request_body)
        }
      end
    end
  end
end
