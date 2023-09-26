# frozen_string_literal: true

module Gitlab
  module Llm
    class ChatResponseService < ResponseService
      AI_ACTION = 'chat'

      # Chat needs to broadcast the data to all clients of a user.
      # This is accomplished by subscribing to the `ai_action: "chat"`.
      # We need to remove any `client_subscription_id` that gets passed as the `client_subscription_id` is only
      # used for the streamed response.
      # https://gitlab.com/gitlab-org/gitlab/-/issues/423080
      def initialize(context, basic_options)
        super(context, basic_options.except(:client_subscription_id).merge(ai_action: AI_ACTION))
      end
    end
  end
end
