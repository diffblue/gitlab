# frozen_string_literal: true

module CodeSuggestions
  class TaskSelector
    # Regex is looking for something that looks like a _single line_ code comment.
    # It looks for GitLab Duo Generate and at least 10 characters
    # afterwards.
    # It is case-insensitive.
    # It searches for the last instance of a match by looking for the end
    # of a text block and an optional line break.
    GENERATE_COMMENT_PREFIX = %r{(?<comment>--|#|//)[ \t]?GitLab Duo Generate:[ \t]*(?<instruction>[^\r\n]{10,})\s*\Z}im
    GENERATE_COMMENT_NO_PREFIX = %r{(?<comment>--|#|//)[ \t]?[ \t]*(?<instruction>[^\r\n]{10,})\s*\Z}im

    # TODO: Remove `skip_generate_comment_prefix` when `code_suggestions_no_comment_prefix` feature flag
    # is removed https://gitlab.com/gitlab-org/gitlab/-/issues/424879
    def self.task(params:, unsafe_passthrough_params: {})
      prefix = params.dig(:current_file, :content_above_cursor)
      prefix_regex = params[:skip_generate_comment_prefix] ? GENERATE_COMMENT_NO_PREFIX : GENERATE_COMMENT_PREFIX

      result = CodeSuggestions::InstructionsExtractor.extract(prefix, prefix_regex)
      if result.empty?
        return CodeSuggestions::Tasks::CodeCompletion.new(unsafe_passthrough_params: unsafe_passthrough_params)
      end

      CodeSuggestions::Tasks::CodeGeneration::FromComment.new(
        params: params.merge(
          prefix: result[:prefix].chomp,
          instruction: result[:instruction]
        ),
        unsafe_passthrough_params: unsafe_passthrough_params
      )
    end
  end
end
