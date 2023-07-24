# frozen_string_literal: true

module Gitlab
  module Llm
    module Templates
      class SummarizeReview
        TOTAL_MODEL_TOKEN_LIMIT = 4000

        # 0.5 + 0.25 = 0.75, leaving a 0.25 buffer for the input token limit
        #
        # We want this for 2 reasons:
        # - 25% for output tokens: OpenAI token limit includes both tokenized input prompt as well as the response
        # We may come want to adjust these rations as we learn more, but for now leaving a 25% ration of the total
        # limit seems sensible.
        # - 25% buffer for input tokens: we approximate the token count by dividing character count by 4. That is no
        # very accurate at all, so we need some buffer in case we exceed that so that we avoid getting an error
        # response as much as possible. A better alternative is to use tiktoken_ruby gem which is coming in a
        # follow-up, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117176
        #
        INPUT_TOKEN_LIMIT = (TOTAL_MODEL_TOKEN_LIMIT * 0.5).to_i.freeze

        # approximate that one token is ~4 characters. A better way of doing this is using tiktoken_ruby gem,
        # which is a wrapper on OpenAI's token counting lib in python.
        # see https://help.openai.com/en/articles/4936856-what-are-tokens-and-how-to-count-them
        #
        INPUT_CONTENT_LIMIT = INPUT_TOKEN_LIMIT * 4

        def initialize(draft_notes)
          @draft_notes = draft_notes
        end

        def to_prompt
          <<-PROMPT
          You are acting as the reviewer for this merge request and MUST respond in first person as if you reviewed it and should always use 'I'. You are provided with the corresponding code comment. Use this information to create an overall summary which MUST mention the types of comments left, a comment can be either: question or recommendation. This summary MUST NOT be longer than 3 sentences. This summary MUST give an indication of the topics the review covered. The summary MUST be written in present simple tense and MUST be as concise as possible. The summary MUST also include an estimate of the overall work needed, using any of the following: "small amount of work, decent amount or significant work required" but the comment MUST make sure to note this is only an estimate, for example, "I estimate there is...". Code review comments:

          #{draft_notes_content}
          PROMPT
        end

        private

        attr_reader :draft_notes

        def draft_notes_content
          content = []

          draft_notes.each do |draft_note|
            draft_note_line = "Comment: #{draft_note.note}\n"

            content << draft_note_line if (content.length + draft_note_line.length) < INPUT_CONTENT_LIMIT
          end

          content.join("\n")
        end
      end
    end
  end
end
