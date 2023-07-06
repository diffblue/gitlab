# frozen_string_literal: true

module EE
  module Gitlab
    module Audit
      module Auditor
        extend ::Gitlab::Utils::Override

        override :multiple_audit
        def multiple_audit
          ::Gitlab::Audit::EventQueue.begin!

          return_value = yield

          ::Gitlab::Audit::EventQueue.current
                                     .map { |message| build_event(message) }
                                     .then { |events| record(events) }

          return_value
        ensure
          ::Gitlab::Audit::EventQueue.end!
        end

        override :send_to_stream
        def send_to_stream(events)
          events.each do |event|
            event_name = name
            event.run_after_commit_or_now do
              event.stream_to_external_destinations(use_json: true, event_name: event_name)
            end
          end
        end

        override :audit_enabled?
        def audit_enabled?
          return true if super
          return true if ::License.feature_available?(:admin_audit_log)
          return true if ::License.feature_available?(:extended_audit_events)

          scope.respond_to?(:licensed_feature_available?) && scope.licensed_feature_available?(:audit_events)
        end
      end
    end
  end
end
