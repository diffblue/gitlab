# frozen_string_literal: true

module Llm
  class BaseService
    def initialize(user, resource, options = {})
      @user = user
      @resource = resource
      @options = options
    end

    def execute
      # todo: if not valid an error message should be returned so that there is feedback to the user.
      perform if valid?
    end

    def valid?
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
  end
end
