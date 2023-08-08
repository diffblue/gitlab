# frozen_string_literal: true

module Llm
  class BaseService
    INVALID_MESSAGE = 'AI features are not enabled or resource is not permitted to be sent.'

    def initialize(user, resource, options = {})
      @user = user
      @resource = resource
      @options = options
      @logger = Gitlab::Llm::Logger.build
    end

    def execute
      unless valid?
        logger.info(message: "Returning from Service due to validation")
        return error(INVALID_MESSAGE)
      end

      perform
    end

    def valid?
      return false if resource.respond_to?(:resource_parent) && !resource.resource_parent.member?(user)

      ai_integration_enabled? && user_can_send_to_ai?
    end

    private

    attr_reader :user, :resource, :options, :logger

    def perform
      raise NotImplementedError
    end

    def worker_perform(user, resource, action_name, options)
      request_id = SecureRandom.uuid
      options[:request_id] = request_id
      message = content(action_name)
      payload = {
        request_id: request_id,
        role: ::Gitlab::Llm::Cache::ROLE_USER,
        content: message,
        timestamp: Time.current
      }

      ::Gitlab::Llm::Cache.new(user).add(payload) if cache_response?(options)

      unless options[:internal_request]
        GraphqlTriggers.ai_completion_response(user.to_global_id, resource&.to_global_id, payload)
      end

      return success(payload) if no_worker_message?(message)

      logger.debug(
        message: "Enqueuing CompletionWorker",
        user_id: user.id,
        resource_id: resource&.id,
        resource_class: resource&.class&.name,
        request_id: request_id,
        action_name: action_name,
        options: options
      )

      if options[:sync] == true
        response_data = ::Llm::CompletionWorker.new.perform(
          user.id, resource&.id, resource&.class&.name, action_name, options
        )
        payload.merge!(response_data)
      else
        ::Llm::CompletionWorker.perform_async(user.id, resource&.id, resource&.class&.name, action_name, options)
      end

      success(payload)
    end

    def ai_integration_enabled?
      Feature.enabled?(:openai_experimentation)
    end

    # https://gitlab.com/gitlab-org/gitlab/-/issues/413520
    def user_can_send_to_ai?
      return true unless ::Gitlab.com?

      user.any_group_with_ai_available?
    end

    def success(data = {})
      ServiceResponse.success(payload: data)
    end

    def error(message)
      ServiceResponse.error(message: message)
    end

    def content(action_name)
      action_name.to_s.humanize
    end

    def no_worker_message?(content)
      content == ::Gitlab::Llm::CachedMessage::RESET_MESSAGE
    end

    def cache_response?(options)
      return false if options[:internal_request]

      options.fetch(:cache_response, false)
    end
  end
end
