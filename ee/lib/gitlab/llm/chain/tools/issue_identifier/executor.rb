# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module IssueIdentifier
          class Executor < Tool
            include Concerns::AiDependent

            attr_accessor :retries

            MAX_RETRIES = 3
            RESOURCE_NAME = 'issue'
            NAME = "IssueIdentifier"
            DESCRIPTION = 'Useful tool when you need to identify a specific issue. ' \
                          'Do not use this tool if you have already identified the issue.' \
                          'In this context, word `issue` means core building block in GitLab that enable ' \
                          'collaboration, discussions, planning and tracking of work.

'
            EXAMPLE =
              <<~PROMPT
                Question: Please identify the author of http://gitlab.example/ai/test/-/issues/1 issue
                Picked tools: First: "IssueIdentifier" tool, second: "ResourceReader" tool.
                Reason: You have access to the same resources as user who asks a question.
                  There is issue identifier in the question, so you need to use "IssueIdentifier" tool.
                  Once the issue is identified, you should use "ResourceReader" tool to fetch relevant information
                  about the resource. Based on this information you can present final answer.
              PROMPT

            PROVIDER_PROMPT_CLASSES = {
              anthropic: ::Gitlab::Llm::Chain::Tools::IssueIdentifier::Prompts::Anthropic,
              vertex_ai: ::Gitlab::Llm::Chain::Tools::IssueIdentifier::Prompts::VertexAi
            }.freeze

            PROJECT_REGEX = {
              'url' => Issue.link_reference_pattern,
              'reference' => Issue.reference_pattern
            }.freeze

            # our template
            PROMPT_TEMPLATE = [
              Utils::Prompt.as_system(
                <<~PROMPT
                You can fetch information about a resource called: an issue.
                An issue can be referenced by url or numeric IDs preceded by symbol.
                ResourceIdentifierType can only be one of [current, iid, url, reference]
                ResourceIdentifier can be "current", number, url. If ResourceIdentifier is not a number or a url
                use "current".

                Provide your answer in JSON form! The answer should be just the JSON without any other commentary!
                Make sure the response is a valid JSON. Follow the exact JSON format:
                Question: the user question
                Response:
                ```json
                {
                  "ResourceIdentifierType": <ResourceIdentifierType>
                  "ResourceIdentifier": <ResourceIdentifier>
                }
                ```

                Examples of issue reference identifier:

                Question: The user question or request may include https://some.host.name/some/long/path/-/issues/410692
                Response:
                ```json
                {
                  "ResourceIdentifierType": "url",
                  "ResourceIdentifier": "https://some.host.name/some/long/path/-/issues/410692"
                }
                ```

                Question: the user question or request may include: #12312312
                Response:
                ```json
                {
                  "ResourceIdentifierType": "iid",
                  "ResourceIdentifier": 12312312
                }
                ```

                Question: the user question or request may include long/groups/path#12312312
                Response:
                ```json
                {
                  "ResourceIdentifierType": "reference",
                  "ResourceIdentifier": "long/groups/path#12312312"
                }
                ```

                Question: Summarize the current issue
                Response:
                ```json
                {
                  "ResourceIdentifierType": "current",
                  "ResourceIdentifier": "issue"
                }
                ```

                Begin!
                PROMPT
              ),
              Utils::Prompt.as_assistant("%<suggestions>s"),
              Utils::Prompt.as_user("Question: %<input>s"),
              Utils::Prompt.as_user("Response:")
            ].freeze

            def initialize(context:, options:)
              super
              @retries = 0
            end

            def perform
              MAX_RETRIES.times do
                json = extract_json(request)
                issue = identify_issue(json[:ResourceIdentifierType], json[:ResourceIdentifier])

                # if issue not found then return an error as the answer.
                return not_found unless issue

                # now the issue in context is being referenced in user input.
                context.resource = issue
                content = "I identified the issue #{json[:ResourceIdentifier]}."

                logger.debug(message: "Answer", class: self.class.to_s, content: content)
                return Answer.new(status: :ok, context: context, content: content, tool: nil)
              rescue JSON::ParserError
                # try to help out AI to fix the JSON format by adding the error as an observation
                self.retries += 1

                error_message = "\nObservation: JSON has an invalid format. Please retry"
                logger.error(message: "Error", class: self.class.to_s, error: error_message)

                options[:suggestions] += error_message
              rescue StandardError => e
                logger.error(message: "Error", error: e.message, class: self.class.to_s)
                return Answer.error_answer(context: context, content: _("Unexpected error"))
              end

              not_found
            end

            private

            def authorize
              Utils::Authorizer.context_authorized?(context: context)
            end

            def extract_json(response)
              response = (Utils::TextProcessing.text_before_stop_word(response, /Question:/) || response).to_s.strip
              content_after_ticks = response.split(/```json/, 2).last
              content_between_ticks = content_after_ticks&.split(/```/, 2)&.first

              Gitlab::Json.parse(content_between_ticks&.strip.to_s).with_indifferent_access
            end

            def identify_issue(resource_identifier_type, resource_identifier)
              return context.resource if current_resource?(resource_identifier, resource_name)

              issue = case resource_identifier_type
                      when 'iid'
                        by_iid(resource_identifier)
                      when 'url', 'reference'
                        extract_issue(resource_identifier, resource_identifier_type)
                      end

              issue if Utils::Authorizer.resource_authorized?(resource: issue, user: context.current_user)
            end

            def by_iid(resource_identifier)
              return unless projects_from_context

              issues = Issue.in_projects(projects_from_context).iid_in(resource_identifier.to_i)

              return issues.first if issues.one?
            end

            def extract_issue(text, type)
              project = extract_project(text, type)
              return unless project

              extractor = Gitlab::ReferenceExtractor.new(project, context.current_user)
              extractor.analyze(text, {})
              issues = extractor.issues

              return issues.first if issues.one?
            end

            def extract_project(text, type)
              projects_from_context.first unless projects_from_context.blank?

              project_path = text.match(PROJECT_REGEX[type])&.values_at(:namespace, :project)
              context.current_user.authorized_projects.find_by_full_path(project_path.join('/')) if project_path
            end

            # This method should not be memoized because the options change each iteration, e.g options[:suggestions]
            def base_prompt
              {
                prompt: Utils::Prompt.no_role_text(PROMPT_TEMPLATE, options),
                options: {}
              }
            end

            def already_used_answer
              resource = context.resource
              content = "You already have identified the issue #{resource.to_global_id}, read carefully."
              logger.debug(message: "Answer", class: self.class.to_s, content: content)

              ::Gitlab::Llm::Chain::Answer.new(
                status: :not_executed, context: context, content: content, tool: nil, is_final: false
              )
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
