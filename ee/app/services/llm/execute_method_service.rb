# frozen_string_literal: true

module Llm
  class ExecuteMethodService < BaseService
    # This list of methods will expand as we add more methods to support.
    # Could also be abstracted to another class specific to find the appropriate method service.
    METHODS = {
      summarize_comments: Llm::GenerateSummaryService,
      explain_code: Llm::ExplainCodeService
    }.freeze

    def initialize(user, resource, method, options = {})
      super(user, resource, options)

      @method = method
    end

    def execute
      return error('Unknown method') unless METHODS.key?(method)

      result = METHODS[method].new(user, resource, options).execute

      return success(result.payload) if result.success?

      error(result.message)
    end

    private

    attr_reader :method
  end
end
