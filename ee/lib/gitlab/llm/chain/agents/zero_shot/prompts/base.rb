# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Agents
        module ZeroShot
          module Prompts
            class Base
              def self.prompt(options)
                base_prompt = Utils::Prompt.no_role_text(
                  ::Gitlab::Llm::Chain::Agents::ZeroShot::Executor::PROMPT_TEMPLATE, options
                )

                "#{Utils::Prompt.default_system_prompt}\n\n#{base_prompt}"
              end
            end
          end
        end
      end
    end
  end
end
