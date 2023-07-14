# frozen_string_literal: true

module Gitlab
  module Llm
    module Templates
      class SummarizeSubmittedReview
        # We're using the chat model for this.
        # Based on https://cloud.google.com/vertex-ai/docs/generative-ai/learn/models#foundation_models,
        # the input token limit is 4,096 tokens.
        MODEL_INPUT_TOKEN_LIMIT = 4096

        # Based on https://cloud.google.com/vertex-ai/docs/generative-ai/learn/models#chat_model_parameters,
        # a token is approximately 4 characters. Since we also need to take the
        # prompt we send into consideration, we reduce the limit by a bit and only
        # take 95% of the model input token limit.
        INPUT_CONTENT_LIMIT = (MODEL_INPUT_TOKEN_LIMIT * 0.95) * 4

        def initialize(review)
          @review = review
        end

        def to_prompt
          <<-PROMPT
            You are a sophisticated code review assistant.
            You are acting as the reviewer for this merge request and MUST respond in first person as if you reviewed it and should always use 'I'.
            You are provided with the corresponding code comment.
            Use this information to create an overall summary which MUST mention the types of comments left, a comment can be either: question or recommendation.
            This summary MUST NOT be longer than 3 sentences.
            This summary MUST give an indication of the topics the review covered.
            The summary MUST be written in present simple tense and MUST be as concise as possible.
            The summary MUST also include an estimate of the overall work needed, using any of the following: "small amount of work, decent amount or significant work required" but the comment MUST make sure to note this is only an estimate, for example, "I estimate there is...".

            Code review comments:
            #{review_content}
          PROMPT
        end

        private

        attr_reader :review

        def review_content
          return unless review.present?

          content = []

          review.notes.each do |note|
            note_line = "Comment: #{note.note}\n\n"

            content << note_line if (content.length + note_line.length) < INPUT_CONTENT_LIMIT
          end

          content.join("\n")
        end
      end
    end
  end
end
