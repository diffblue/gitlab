# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module Completions
        class SummarizeReview < Gitlab::Llm::Completions::Base
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

          def execute(user, merge_request, _ = {})
            return unless user
            return unless merge_request

            draft_notes = merge_request.draft_notes.authored_by(user)
            return if draft_notes.empty?

            options = ai_prompt_class.get_options(prepared_draft_notes_content(draft_notes))

            ai_response = Gitlab::Llm::OpenAi::Client.new(user).chat(
              content: nil,
              **options
            )
            response_modifier = Gitlab::Llm::OpenAi::ResponseModifiers::Chat.new(ai_response)

            ::Gitlab::Llm::GraphqlSubscriptionResponseService.new(
              user, merge_request, response_modifier, options: response_options
            ).execute
          end

          private

          def prepared_draft_notes_content(draft_notes)
            draft_notes_content = []

            draft_notes.each do |draft_note|
              draft_note_line = "Comment: #{draft_note.note}\n"

              if (draft_notes_content.length + draft_note_line.length) < INPUT_CONTENT_LIMIT
                draft_notes_content << draft_note_line
              end
            end

            draft_notes_content.join("\n")
          end
        end
      end
    end
  end
end
