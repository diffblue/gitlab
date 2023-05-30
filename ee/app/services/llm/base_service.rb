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
        logger.debug(message: "Returning from Service due to validation")
        return error(INVALID_MESSAGE)
      end

      perform
    end

    def valid?
      return false if resource.respond_to?(:resource_parent) && !resource.resource_parent.member?(user)

      ai_integration_enabled? && resource.send_to_ai?
    end

    private

    attr_reader :user, :resource, :options, :logger

    def perform
      raise NotImplementedError
    end

    def worker_perform(user, resource, action_name, options)
      request_id = SecureRandom.uuid
      options[:request_id] = request_id

      logger.debug(
        message: "Enqueuing CompletionWorker",
        user_id: user.id,
        resource_id: resource.id,
        resource_class: resource.class.name,
        request_id: request_id,
        action_name: action_name
      )

      payload = { request_id: request_id, role: 'user' }
      ::Gitlab::Llm::Cache.new(user).add(payload)

      if options[:sync] == true
        response_data = ::Llm::CompletionWorker.new.perform(
          user.id, resource.id, resource.class.name, action_name, options
        )
        payload.merge!(response_data)
      else
        ::Llm::CompletionWorker.perform_async(user.id, resource.id, resource.class.name, action_name, options)
      end

      success(payload)
    end

    def ai_integration_enabled?
      Feature.enabled?(:openai_experimentation)
    end

    def success(data = {})
      ServiceResponse.success(payload: data)
    end

    def error(message)
      ServiceResponse.error(message: message)
    end
  end
end
