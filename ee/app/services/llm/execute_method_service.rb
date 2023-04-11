# frozen_string_literal: true

module Llm
  class ExecuteMethodService
    METHODS = {
      summarize_comments: nil
    }.freeze

    def initialize(user, resource, method, options = {}); end

    def execute
      ServiceResponse.success
    end
  end
end
