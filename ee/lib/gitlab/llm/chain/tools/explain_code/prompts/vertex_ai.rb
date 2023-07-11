# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module ExplainCode
          module Prompts
            class VertexAi
              def self.prompt(variables)
                prompt = Utils::Prompt.no_role_text(
                  ::Gitlab::Llm::Chain::Tools::ExplainCode::Executor::PROMPT_TEMPLATE, variables
                )

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
