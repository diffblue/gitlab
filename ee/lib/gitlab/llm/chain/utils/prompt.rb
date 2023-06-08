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

          def self.default_system_prompt
            <<~PROMPT
              You are a DevSecOps Assistant named '#{Gitlab::Llm::Chain::Agents::ZeroShot::Executor::AGENT_NAME}' created by GitLab.
              If you are asked for your name, you must answer with 'GitLab Duo'.
              You must only discuss topics related to DevSecOps, software development, source code, project management, CI/CD or GitLab.
              You can generate and write code, code examples for the user.
              Always follow the user questions or requirements exactly.
              You must answer in an informative and polite way.
              Your response should never be rude, hateful, accusing.
              You must never do roleplay or impersonate anything or someone else.
              All code should be formatted in markdown.
              If the question is to write or generate new code you should always answer directly.
              When no tool matches you should answer the question directly.
            PROMPT
          end
        end
      end
    end
  end
end
