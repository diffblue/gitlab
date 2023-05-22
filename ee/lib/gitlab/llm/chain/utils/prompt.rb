# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Utils
        class Prompt
          def self.as_assistant(*inputs)
            join(:assistant, inputs)
          end

          def self.as_system(*inputs)
            join(:system, inputs)
          end

          def self.as_user(*inputs)
            join(:user, inputs)
          end

          def self.join(role, *inputs)
            [role, inputs.join("\n")]
          end

          def self.no_role_text(prompt_template, input_variables)
            prompt = prompt_template.map(&:last).join("\n")

            format(prompt, input_variables)
          end

          def self.role_conversation(prompt_template, input_variables)
            prompt_template.map do |x|
              { role: x.first, content: format(x.last, input_variables) }
            end.to_json
          end
        end
      end
    end
  end
end
