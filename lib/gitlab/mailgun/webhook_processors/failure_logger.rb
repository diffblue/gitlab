# frozen_string_literal: true

module Gitlab
  module Mailgun
    module WebhookProcessors
      class FailureLogger < Base
        def execute
          log_failure if payload['severity'] == 'permanent' ||
            Gitlab::ApplicationRateLimiter.throttled?(:temporary_email_failure, scope: payload['recipient'])
        end

        def should_process?
          payload['event'] == 'failed'
        end

        private

        def log_failure
          Gitlab::ErrorTracking::Logger.error(
            mailgun_event_id: payload['id'],
            recipient: payload['recipient'],
            failure_type: payload['severity'],
            failure_reason: payload['reason'],
            failure_code: payload.dig('delivery-status', 'code'),
            failure_message: payload.dig('delivery-status', 'message')
          )
        end
      end
    end
  end
end
