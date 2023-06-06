# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module ExplainCode
          module Prompts
            class Anthropic
              def self.prompt(options)
                base_prompt = Utils::Prompt.no_role_text(
                  ::Gitlab::Llm::Chain::Tools::ExplainCode::Executor::PROMPT_TEMPLATE, options
                )
                "\n\nHuman: #{base_prompt}\n\nAssistant:"
              end
            end
          end
        end
      end
    end
  end
end
