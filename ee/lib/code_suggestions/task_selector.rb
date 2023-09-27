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
    ALWAYS_GENERATE_PREFIX = %r{.*?}

    INTENT_COMPLETION = 'completion'
    INTENT_GENERATION = 'generation'

    # TODO: Remove `skip_generate_comment_prefix` when `code_suggestions_no_comment_prefix` feature flag
    # is removed https://gitlab.com/gitlab-org/gitlab/-/issues/424879
    def self.task(params:, unsafe_passthrough_params: {})
      prefix = params.dig(:current_file, :content_above_cursor)

      result = CodeSuggestions::InstructionsExtractor.extract(prefix, prefix_regex(params))

      intent = params[:intent] || (result.empty? ? INTENT_COMPLETION : INTENT_GENERATION)

      if intent == INTENT_COMPLETION
        return CodeSuggestions::Tasks::CodeCompletion.new(unsafe_passthrough_params: unsafe_passthrough_params)
      end

      CodeSuggestions::Tasks::CodeGeneration::FromComment.new(
        params: params.merge(
          prefix: result[:prefix]&.chomp || prefix,
          instruction: result[:instruction]
        ),
        unsafe_passthrough_params: unsafe_passthrough_params
      )
    end

    def self.prefix_regex(params)
      return ALWAYS_GENERATE_PREFIX if params[:intent] == INTENT_GENERATION
      return GENERATE_COMMENT_NO_PREFIX if params[:skip_generate_comment_prefix]

      GENERATE_COMMENT_PREFIX
    end
  end
end
