# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module Completions
        class SummarizeAllOpenNotes
          TOTAL_MODEL_TOKEN_LIMIT = 4000

          # 0.5 + 0.25 = 0.75, leaving a 0.25 buffer for the input token limit
          #
          # We want this for 2 reasons:
          # - 25% for output tokens: OpenAI token limit includes both tokenized input prompt as well as the response
          # We may come want to adjust these rations as we learn more, but for now leaving a 25% ration of the total
          # limit seems sensible.
          # - 25% buffer for input tokens: we aproximate the token count by dividing character count by 4. That is no
          # very accurate at all, so we need some buffer in case we exceed that so that we avoid getting an error
          # response as much as possible. A better alternative is to use tiktoken_ruby gem which is coming in a
          # follow-up, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117176
          INPUT_TOKEN_LIMIT = (TOTAL_MODEL_TOKEN_LIMIT * 0.5).to_i.freeze

          # approximate that one token is ~4 characters. A better way of doing this is using tiktoken_ruby gem,
          # which is a wrapper on OpenAI's token counting lib in python.
          # see https://help.openai.com/en/articles/4936856-what-are-tokens-and-how-to-count-them
          INPUT_CONTENT_LIMIT = INPUT_TOKEN_LIMIT * 4

          def initialize(ai_prompt_class)
            @ai_prompt_class = ai_prompt_class
          end

          def execute(user, issuable, _ = {})
            return unless user
            return unless issuable

            notes = issuable.notes.for_summarize_by_ai
            return if notes.empty?

            # todo: this is not great, loads all notes into memory, but we know this and we'll fix this
            # todo: see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117176 for a follow-up
            notes_content = notes.first(100).pluck(:note).join("\n") # rubocop: disable CodeReuse/ActiveRecord

            options = ai_prompt_class.get_options(notes_content[0..INPUT_CONTENT_LIMIT])

            ai_response = Gitlab::Llm::OpenAi::Client.new(user).chat(
              content: nil,
              **options
            )

            ::Gitlab::Llm::OpenAi::ResponseService.new(user, issuable, ai_response, options: {})
              .execute(Gitlab::Llm::OpenAi::ResponseModifiers::Chat.new)
          end

          private

          attr_reader :ai_prompt_class
        end
      end
    end
  end
end
