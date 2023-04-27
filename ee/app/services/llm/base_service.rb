# frozen_string_literal: true

module Llm
  class BaseService
    INVALID_MESSAGE = 'AI features are not enabled or resource is not permitted to be sent.'

    def initialize(user, resource, options = {})
      @user = user
      @resource = resource
      @options = options
    end

    def execute
      return error(INVALID_MESSAGE) unless valid?

      perform
    end

    def valid?
      return false if resource.respond_to?(:resource_parent) && !resource.resource_parent.member?(user)

      ai_integration_enabled? && resource.send_to_ai?
    end

    private

    attr_reader :user, :resource, :options

    def perform
      raise NotImplementedError
    end

    def ai_integration_enabled?
      Feature.enabled?(:openai_experimentation)
    end

    def success(data = nil)
      ServiceResponse.success(payload: data)
    end

    def error(message)
      ServiceResponse.error(message: message)
    end
  end
end
