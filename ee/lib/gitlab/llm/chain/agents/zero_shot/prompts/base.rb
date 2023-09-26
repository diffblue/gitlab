# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Agents
        module ZeroShot
          module Prompts
            class Base
              def self.base_prompt(options)
                base_prompt = Utils::Prompt.no_role_text(
                  options.fetch(:prompt_version),
                  options
                )

                "#{Utils::Prompt.default_system_prompt}\n\n#{base_prompt}"
              end

              def self.current_code_prompt(blob)
                "The current code file that user sees is #{blob.path} and has the following content:\n#{blob.data}\n\n"
              end
            end
          end
        end
      end
    end
  end
end
