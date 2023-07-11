# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module SummarizeComments
          module Prompts
            class OpenAi
              TOTAL_MODEL_TOKEN_LIMIT = 4000
              # 0.5 + 0.25 = 0.75, leaving a 0.25 buffer for the input token limit
              #
              # We want this for 2 reasons:
              # - 25% for output tokens: OpenAI token limit includes both tokenized input prompt as well as the response
              # We may come want to adjust these rations as we learn more, but for now leaving a 25% ration of the total
              # limit seems sensible.
              # - 25% buffer for input tokens: we approximate the token count by dividing character count by 4.
              # That is not very accurate at all, so we need some buffer in case we exceed that so that we avoid
              # getting an error response as much as possible.
              INPUT_TOKEN_LIMIT = (TOTAL_MODEL_TOKEN_LIMIT * 0.5).to_i.freeze

              # approximate that one token is ~4 characters. A better way of doing this is using tiktoken_ruby gem,
              # which is a wrapper on OpenAI's token counting lib in python.
              # see https://help.openai.com/en/articles/4936856-what-are-tokens-and-how-to-count-them
              INPUT_CONTENT_LIMIT = (INPUT_TOKEN_LIMIT * 4).to_i.freeze
              OUTPUT_TOKEN_LIMIT = (TOTAL_MODEL_TOKEN_LIMIT * 0.25).to_i.freeze

              def self.prompt(options)
                prompt = Utils::Prompt.no_role_text(
                  ::Gitlab::Llm::Chain::Tools::SummarizeComments::Executor::PROMPT_TEMPLATE, options
                )

                {
                  prompt: prompt,
                  options: {
                    max_tokens: OUTPUT_TOKEN_LIMIT
                  }
                }
              end
            end
          end
        end
      end
    end
  end
end
