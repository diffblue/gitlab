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
                  options.fetch(:prompt_version),
                  options
                )

                { prompt: "#{Utils::Prompt.default_system_prompt}\n\n#{base_prompt}", options: {} }
              end
            end
          end
        end
      end
    end
  end
end
