# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module JsonReader
          module Prompts
            class Anthropic
              CHARACTERS_IN_TOKEN = 4

              # 100_000 tokens limit documentation:  https://docs.anthropic.com/claude/reference/selecting-a-model
              TOTAL_MODEL_TOKEN_LIMIT = 100_000
              INPUT_TOKEN_LIMIT = (TOTAL_MODEL_TOKEN_LIMIT * 0.8).to_i.freeze
              # approximate that one token is ~4 characters.
              MAX_CHARACTERS = (INPUT_TOKEN_LIMIT * CHARACTERS_IN_TOKEN).to_i.freeze

              def self.prompt(options)
                base_prompt = Utils::Prompt.no_role_text(
                  ::Gitlab::Llm::Chain::Tools::JsonReader::Executor::PROMPT_TEMPLATE, options
                ).concat("\nThought:")

                Requests::Anthropic.prompt("\n\nHuman: #{base_prompt}\n\nAssistant:")
              end
            end
          end
        end
      end
    end
  end
end
