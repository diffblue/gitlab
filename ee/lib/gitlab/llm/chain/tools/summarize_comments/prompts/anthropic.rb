# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module SummarizeComments
          module Prompts
            class Anthropic
              TOTAL_MODEL_TOKEN_LIMIT = 100_000
              INPUT_TOKEN_LIMIT = (TOTAL_MODEL_TOKEN_LIMIT * 0.8).to_i.freeze
              # approximate that one token is ~4 characters.
              INPUT_CONTENT_LIMIT = (INPUT_TOKEN_LIMIT * 4).to_i.freeze
              OUTPUT_TOKEN_LIMIT = 2048
              MODEL = 'claude-1.3-100k'

              def self.prompt(options)
                base_prompt = Utils::Prompt.no_role_text(
                  ::Gitlab::Llm::Chain::Tools::SummarizeComments::Executor::PROMPT_TEMPLATE, options
                )

                Requests::Anthropic.prompt(
                  "\n\nHuman: #{base_prompt}\n\nAssistant:",
                  options: {
                    model: MODEL,
                    max_tokens_to_sample: OUTPUT_TOKEN_LIMIT
                  }
                )
              end
            end
          end
        end
      end
    end
  end
end
