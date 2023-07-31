# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module JsonReader
          module Prompts
            class VertexAi
              # source: https://cloud.google.com/vertex-ai/docs/generative-ai/learn/models
              TOTAL_MODEL_TOKEN_LIMIT = 8192
              INPUT_TOKEN_LIMIT = (TOTAL_MODEL_TOKEN_LIMIT * 0.8).to_i.freeze
              # approximate that one token is ~4 characters.
              MAX_CHARACTERS = (INPUT_TOKEN_LIMIT * 4).to_i.freeze

              def self.prompt(options)
                prompt = Utils::Prompt.no_role_text(
                  ::Gitlab::Llm::Chain::Tools::JsonReader::Executor::PROMPT_TEMPLATE, options
                ).concat("\nThought:")

                {
                  prompt: prompt,
                  options: {}
                }
              end
            end
          end
        end
      end
    end
  end
end
