# frozen_string_literal: true

module CodeSuggestions
  class ModelSelector
    # Regex is looking for something that looks like a _single line_ code comment.
    # It looks for GitLab Duo Generate and at least 10 characters
    # afterwards.
    # It is case-insensitive.
    # It searches for the last instance of a match by looking for the end
    # of a text block and an optional line break.
    GENERATE_COMMENT_PREFIX = %r{(--|#|//)\s?GitLab Duo Generate:(.{10,})\s*\z}i

    def initialize(prefix:)
      @prefix = prefix
    end

    def task_type
      return :code_generation if @prefix&.match?(GENERATE_COMMENT_PREFIX)

      :code_completion
    end

    def endpoint_name
      task_type.eql?(:code_generation) ? 'generations' : 'completions'
    end
  end
end
