# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Agents
        module ZeroShot
          module Prompts
            class VertexAi
              def self.prompt(options)
                Utils::Prompt.no_role_text(
                  ::Gitlab::Llm::Chain::Agents::ZeroShot::Executor::PROMPT_TEMPLATE, options
                )
              end
            end
          end
        end
      end
    end
  end
end
