# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module JsonReader
          module Prompts
            class Anthropic
              def self.prompt(options)
                base_prompt = Utils::Prompt.no_role_text(
                  ::Gitlab::Llm::Chain::Tools::JsonReader::Executor::PROMPT_TEMPLATE, options
                ).concat("\nThought:")
                "\n\nHuman: #{base_prompt}\n\nAssistant:"
              end
            end
          end
        end
      end
    end
  end
end
