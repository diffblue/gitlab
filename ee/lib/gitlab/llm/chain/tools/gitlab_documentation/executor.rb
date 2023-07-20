# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module GitlabDocumentation
          class Executor < Tool
            NAME = 'GitlabDocumentation'
            RESOURCE_NAME = 'documentation answer'
            DESCRIPTION =
              <<-PROMPT
                This tool is beneficial when you need to answer questions concerning GitLab and its features.
                Questions can be about GitLab's projects, groups, issues, merge requests,
                epics, milestones, labels, CI/CD pipelines, git repositories, and more.
              PROMPT

            EXAMPLE =
              <<~PROMPT
                Question: How do I set up a new project?
                Picked tools: "GitlabDocumentation" tool.
                Reason: Question is about inner working of GitLab. "GitlabDocumentation" tool is the right one for
                the job.
              PROMPT

            def perform
              # We can't reuse the injected client here but need to call TanukiBot as it uses the
              # embedding database and calls the OpenAI API internally.
              logger.debug(message: "Calling TanukiBot", class: self.class.to_s)
              response = Gitlab::Llm::TanukiBot.new(
                current_user: context.current_user,
                question: options[:input]
              ).execute
              content = Gitlab::Llm::Anthropic::ResponseModifiers::TanukiBot.new(response.body).response_body

              Gitlab::Llm::Chain::Answer.final_answer(context: context, content: content)
            end

            private

            def authorize
              # Every user with access to a paid namespace that supports AI features has access to
              # the documentation tool.
              Utils::Authorizer.user_authorized?(user: context.current_user)
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
