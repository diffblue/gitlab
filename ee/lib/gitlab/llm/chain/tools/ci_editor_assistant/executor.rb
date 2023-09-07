# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module CiEditorAssistant
          class Executor < Tool
            include Concerns::AiDependent

            NAME = 'CiEditorAssistant'
            HUMAN_NAME = 'CI Assistant'
            RESOURCE_NAME = 'ci editor answer'

            DESCRIPTION =
              <<~DESC
                Useful tool when you need to provide suggestions regarding anything related to ".gitlab-ci.yml" file.
                It helps with questions related to deploying code, configuring CI/CD pipelines, defining CI jobs, or environments.
              DESC
            EXAMPLE =
              <<~PROMPT
                Question: Please create a deployment configuration for a node.js application.
                Picked tools: "CiEditorAssistant" tool.
                Reason: You have asked a question related to deployment of an application or CI/CD pipelines.
                  "CiEditorAssistant" tool can assist with this kind of questions.
              PROMPT

            PROVIDER_PROMPT_CLASSES = {
              anthropic: ::Gitlab::Llm::Chain::Tools::CiEditorAssistant::Prompts::Anthropic,
              vertex_ai: ::Gitlab::Llm::Chain::Tools::CiEditorAssistant::Prompts::VertexAi
            }.freeze

            PROMPT_TEMPLATE = [
              Utils::Prompt.as_system(
                <<~PROMPT
                System: You are an ai assistant talking to a devops or software engineer.
                You should coach users to author a ".gitlab-ci.yml" file which can be used to create a GitLab pipeline.
                Please provide concrete and detailed yaml that implements what the user asks for as closely as possible, assuming a single yaml file will be used.

                Think step by step to provide the most accurate solution to the user problem. Make sure that all the stages you've defined in the yaml file are actually used in it.
                If you realise you require more input from the user, please describe what information is missing and ask them to provide it. Specifically check, if you have information about the application you're providing a configuration for, for example, the programming language used, or deployment targets.
                If any configuration is missing, such as configuration variables, connection strings, secrets and so on, assume it will be taken from GitLab Ci/CD variables. Please include the variables configuration block that would use these Ci/CD variables.

                Please include the commented sections explaining every configuration block, unless the user explicitly asks you to skip or not include comments.
                PROMPT
              ),
              Utils::Prompt.as_user("Question: %<input>s")
            ].freeze

            def perform
              Answer.new(status: :ok, context: context, content: request, tool: nil)
            rescue StandardError
              Answer.error_answer(context: context, content: _("Unexpected error"))
            end

            private

            def authorize
              Utils::Authorizer.context_authorized?(context: context)
            end

            def resource_name
              RESOURCE_NAME
            end
          end
        end
      end
    end
  end
end
