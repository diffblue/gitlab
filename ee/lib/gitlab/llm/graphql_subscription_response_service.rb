# frozen_string_literal: true

module Gitlab
  module Llm
    class GraphqlSubscriptionResponseService < BaseService
      def initialize(user, resource, response_modifier, options:)
        @user = user
        @resource = resource
        @response_modifier = response_modifier
        @options = options
        @logger = Gitlab::Llm::Logger.build
      end

      def execute
        return unless user

        data = {
          id: SecureRandom.uuid,
          request_id: options[:request_id],
          content: response_modifier.response_body,
          errors: response_modifier.errors,
          role: options[:role] || ChatMessage::ROLE_ASSISTANT,
          timestamp: Time.current,
          type: options.fetch(:type, nil),
          chunk_id: options.fetch(:chunk_id, nil),
          extras: response_modifier.extras
        }

        logger.debug(
          message: "Broadcasting AI response",
          data: data,
          options: options
        )

        response_data = data.slice(:request_id, :errors, :role, :content, :timestamp, :extras)

        unless options[:internal_request]
          Gitlab::Llm::ChatStorage.new(user).add(response_data) if options[:cache_response]

          subscription_arguments = { user_id: user.to_global_id, resource_id: resource&.to_global_id }

          if options[:client_subscription_id]
            subscription_arguments[:client_subscription_id] = options[:client_subscription_id]
          end

          # Clients that use the `ai_action` parameter to subscribe on, no longer ned to subscribe on the
          # `resource_id`. This enables us to broadcast chat messages to clients, regardless of their `resource_id`.
          # https://gitlab.com/gitlab-org/gitlab/-/issues/423080
          if options[:ai_action]
            subscription_arguments[:ai_action] = options[:ai_action]
            subscription_arguments.delete(:resource_id)
          end

          GraphqlTriggers.ai_completion_response(subscription_arguments, data)
        end

        response_data
      end

      private

      attr_reader :user, :resource, :response_modifier, :options, :logger
    end
  end
end
