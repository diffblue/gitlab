# frozen_string_literal: true

module Llm
  class ExecuteMethodService < BaseService
    # This list of methods will expand as we add more methods to support.
    # Could also be abstracted to another class specific to find the appropriate method service.
    METHODS = {
      summarize_comments: Llm::GenerateSummaryService
    }.freeze

    def initialize(user, resource, method, options = {})
      super(user, resource, options)

      @method = method
    end

    def execute
      return error('Unknown method') unless METHODS.key?(method)

      success(METHODS[method].new(user, resource, options).execute)
    end

    private

    attr_reader :method

    def success(data)
      ServiceResponse.success(payload: data)
    end

    def error(message)
      ServiceResponse.error(message: message)
    end
  end
end
