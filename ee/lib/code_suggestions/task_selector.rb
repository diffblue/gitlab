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
    GENERATE_COMMENT_NO_PREFIX =
      %r{(?<prefix>.*)(?<comment>--|#|//)[ \t]?[ \t]*(?<instruction>[^\r\n]{10,})\s*\Z}im
    PREFIX_MAX_SIZE = 100_000

    # TODO: Remove `skip_generate_comment_prefix` when `code_suggestions_no_comment_prefix` feature flag
    # is removed https://gitlab.com/gitlab-org/gitlab/-/issues/424879
    def self.task(skip_generate_comment_prefix:, params:)
      prefix = params.dig('current_file', 'content_above_cursor')
      prefix_regex = skip_generate_comment_prefix ? GENERATE_COMMENT_NO_PREFIX : GENERATE_COMMENT_PREFIX
      match = comment_match(prefix, prefix_regex)

      return CodeSuggestions::Tasks::CodeCompletion.new(params.merge(prefix: prefix)) unless match

      CodeSuggestions::Tasks::CodeGeneration::FromComment.new(
        params.merge(
          prefix: match[:prefix].chomp,
          instruction: match[:instruction]
        )
      )
    end

    def self.comment_match(prefix, prefix_regex)
      return unless prefix
      # This is a short-term fix for avoiding processing too long strings,
      # but we should rather define proper set of input parameters for REST API
      # endpoint with its limits:
      # https://gitlab.com/gitlab-org/gitlab/-/issues/424724
      return if prefix.size > PREFIX_MAX_SIZE

      prefix&.match(prefix_regex)
    end
    private_class_method :comment_match
  end
end
