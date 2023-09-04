# frozen_string_literal: true

module Gitlab
  module Llm
    module Concerns
      module EventTracking
        extend ActiveSupport::Concern

        def track_prompt_size(token_size)
          Gitlab::Tracking.event(
            self.class.to_s,
            "tokens_per_user_request_prompt",
            label: tracking_context[:action].to_s,
            property: tracking_context[:request_id],
            user: user,
            value: token_size
          )
        end

        def track_response_size(token_size)
          Gitlab::Tracking.event(
            self.class.to_s,
            "tokens_per_user_request_response",
            label: tracking_context[:action].to_s,
            property: tracking_context[:request_id],
            user: user,
            value: token_size
          )
        end
      end
    end
  end
end
