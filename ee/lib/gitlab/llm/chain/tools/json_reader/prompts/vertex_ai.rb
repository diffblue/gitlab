# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module JsonReader
          module Prompts
            class VertexAi
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
