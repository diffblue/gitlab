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

          def self.default_system_prompt(explain_current_blob: false)
            # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/420959
            # Remove the conditional along with the feature flag.
            explain_code_prompt = if explain_current_blob
                                    "\nYou can explain code if the user provided a code snippet and answer directly."
                                  else
                                    ""
                                  end

            <<~PROMPT
              You are a DevSecOps Assistant named '#{Gitlab::Llm::Chain::Agents::ZeroShot::Executor::AGENT_NAME}' created by GitLab.

              By only engaging in discussions pertinent to DevSecOps, software development, source code,
              project management, CI/CD or GitLab, your task is to process this request.
              When questioned about your identity, you must only respond as '#{Gitlab::Llm::Chain::Agents::ZeroShot::Executor::AGENT_NAME}'.

              You can generate and write code, code examples for the user.
              Remember to stick to the user's question or requirements closely and respond in an informative,
              courteous manner. The response shouldn't be rude, hateful, or accusatory. You mustn't engage in any form
              of roleplay or impersonation.

              The generated code should be formatted in markdown.

              If a question cannot be answered with the tools and information given, answer politely that you don’t know.
              #{explain_code_prompt}

              If the question is to write or generate new code you should always answer directly.
              When no tool matches you should answer the question directly.
            PROMPT
          end
        end
      end
    end
  end
end
