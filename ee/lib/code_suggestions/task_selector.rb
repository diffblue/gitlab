# frozen_string_literal: true

module CodeSuggestions
  class TaskSelector
    # Regex is looking for something that looks like a _single line_ code comment.
    # It looks for GitLab Duo Generate and at least 10 characters
    # afterwards.
    # It is case-insensitive.
    # It searches for the last instance of a match by looking for the end
    # of a text block and an optional line break.
    GENERATE_COMMENT_PREFIX = %r{(?<prefix>.*)(?<comment>--|#|//)\s?GitLab Duo Generate:\s*(?<instruction>.{10,})\s*\z}i

    def self.task(params:)
      prefix = params.dig('current_file', 'content_above_cursor')
      match = prefix&.match(GENERATE_COMMENT_PREFIX)

      return CodeSuggestions::Tasks::CodeCompletion.new(params.merge(prefix: prefix)) unless match

      CodeSuggestions::Tasks::CodeGeneration::FromComment.new(
        params.merge(
          prefix: match[:prefix],
          instruction: match[:instruction]
        )
      )
    end
  end
end
