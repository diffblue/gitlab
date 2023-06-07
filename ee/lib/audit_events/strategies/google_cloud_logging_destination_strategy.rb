# frozen_string_literal: true

module AuditEvents
  module Strategies
    class GoogleCloudLoggingDestinationStrategy < ExternalDestinationStrategy
      def initialize(audit_operation, audit_event)
        @logger = GoogleCloud::LoggingService::Logger.new

        super(audit_operation, audit_event)
      end

      def streamable?
        group = audit_event.root_group_entity
        return false if group.nil?
        return false unless group.licensed_feature_available?(:external_audit_events)

        group.google_cloud_logging_configurations.exists?
      end

      private

      def destinations
        group = audit_event.root_group_entity
        group.present? ? group.google_cloud_logging_configurations.to_a : []
      end

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
