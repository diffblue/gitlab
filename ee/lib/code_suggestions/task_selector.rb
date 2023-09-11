# frozen_string_literal: true

module CodeSuggestions
  class TaskSelector
    # Regex is looking for something that looks like a _single line_ code comment.
    # It looks for GitLab Duo Generate and at least 10 characters
    # afterwards.
    # It is case-insensitive.
    # It searches for the last instance of a match by looking for the end
    # of a text block and an optional line break.
    GENERATE_COMMENT_PREFIX =
      %r{(?<prefix>.*)(?<comment>--|#|//)[ \t]?GitLab Duo Generate:[ \t]*(?<instruction>[^\r\n]{10,})\s*\Z}im
    PREFIX_MAX_SIZE = 100_000

    def self.task(params:)
      prefix = params.dig('current_file', 'content_above_cursor')
      match = comment_match(prefix)

      return CodeSuggestions::Tasks::CodeCompletion.new(params.merge(prefix: prefix)) unless match

      CodeSuggestions::Tasks::CodeGeneration::FromComment.new(
        params.merge(
          prefix: match[:prefix].chomp,
          instruction: match[:instruction]
        )
      )
    end

    def self.comment_match(prefix)
      return unless prefix
      # This is a short-term fix for avoiding processing too long strings,
      # but we should rather define proper set of input parameters for REST API
      # endpoint with its limits:
      # https://gitlab.com/gitlab-org/gitlab/-/issues/424724
      return if prefix.size > PREFIX_MAX_SIZE

      prefix&.match(GENERATE_COMMENT_PREFIX)
    end
    private_class_method :comment_match
  end
end
