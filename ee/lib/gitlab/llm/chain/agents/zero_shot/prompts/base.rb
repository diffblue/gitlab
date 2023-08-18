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
                explain_current_blob = options[:explain_current_blob]
                default_system_prompt = Utils::Prompt.default_system_prompt(explain_current_blob: explain_current_blob)

                "#{default_system_prompt}\n\n#{base_prompt}"
              end
            end
          end
        end
      end
    end
  end
end
