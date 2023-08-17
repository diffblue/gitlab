# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module EpicIdentifier
          class Executor < Tool
            include Concerns::AiDependent

            MAX_RETRIES = 3
            RESOURCE_NAME = 'epic'
            NAME = "EpicIdentifier"
            DESCRIPTION = 'Useful tool when you need to identify a specific epic. ' \
                          'Do not use this tool if you have already identified the epic.' \
                          'In this context, word `epic` means high-level building block in GitLab that encapsulates ' \
                          'high-level plans and discussions. Epic can contain multiple issues .' \
                          'Action Input for this tool should be the original question or epic identifier.'

            EXAMPLE =
              <<~PROMPT
                Question: Please identify the author of &epic_identifier epic
                Picked tools: First: "EpicIdentifier" tool, second: "ResourceReader" tool.
                Reason: You have access to the same resources as user who asks a question.
                  There is epic identifier in the question, so you need to use "EpicIdentifier" tool.
                  Once the epic is identified, you should use "ResourceReader" tool to fetch relevant information
                  about the resource. Based on this information you can present final answer.
              PROMPT

            PROVIDER_PROMPT_CLASSES = {
              anthropic: ::Gitlab::Llm::Chain::Tools::EpicIdentifier::Prompts::Anthropic,
              vertex_ai: ::Gitlab::Llm::Chain::Tools::EpicIdentifier::Prompts::VertexAi
            }.freeze

            GROUP_REGEX = {
              'url' => ::Epic.link_reference_pattern,
              'reference' => ::Epic.reference_pattern
            }.freeze

            # our template
            PROMPT_TEMPLATE = [
              Utils::Prompt.as_system(
                <<~PROMPT
                You can fetch information about a resource called: an epic.
                An epic can be referenced by url or numeric IDs preceded by symbol.
                An epic can also be referenced by a GitLab reference.
                A GitLab reference ends with a number preceded by the delimiter & and contains one or more /.
                ResourceIdentifierType can only be one of [current, iid, url, reference]
                ResourceIdentifier can be number, url. If ResourceIdentifier is not a number or a url
                use "current".
                When you see a GitLab reference, ResourceIdentifierType should be reference.

                Make sure the response is a valid JSON. The answer should be just the JSON without any other commentary!
                References in the given question to the current epic can be also for example "this epic" or "that epic",
                referencing the epic that the user currently sees.
                Question: (the user question)
                Response (follow the exact JSON response):
                ```json
                {
                  "ResourceIdentifierType": <ResourceIdentifierType>
                  "ResourceIdentifier": <ResourceIdentifier>
                }
                ```

                Examples of epic reference identifier:

                Question: The user question or request may include https://some.host.name/some/long/path/-/epics/410692
                Response:
                ```json
                {
                  "ResourceIdentifierType": "url",
                  "ResourceIdentifier": "https://some.host.name/some/long/path/-/epics/410692"
                }
                ```

                Question: the user question or request may include: &12312312
                Response:
                ```json
                {
                  "ResourceIdentifierType": "iid",
                  "ResourceIdentifier": 12312312
                }
                ```

                Question: the user question or request may include long/groups/path&12312312
                Response:
                ```json
                {
                  "ResourceIdentifierType": "reference",
                  "ResourceIdentifier": "long/groups/path&12312312"
                }
                ```

                Question: Summarize the current epic
                Response:
                ```json
                {
                  "ResourceIdentifierType": "current",
                  "ResourceIdentifier": "current"
                }
                ```

                Begin!
                PROMPT
              ),
              Utils::Prompt.as_assistant("%<suggestions>s"),
              Utils::Prompt.as_user("Question: %<input>s")
            ].freeze

            def perform
              MAX_RETRIES.times do
                json = extract_json(request)
                epic = identify_epic(json[:ResourceIdentifierType], json[:ResourceIdentifier])

                # if epic not found then return an error as the answer.
                logger.error(message: "Error finding epic", content: json) unless epic
                return not_found unless epic

                # now the epic in context is being referenced in user input.
                context.resource = epic
                content = "I identified the epic #{json[:ResourceIdentifier]}."

                logger.debug(message: "Answer", class: self.class.to_s, content: content)
                return Answer.new(status: :ok, context: context, content: content, tool: nil)
              rescue JSON::ParserError
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
              response = "```json
                    \{
                      \"ResourceIdentifierType\": \"" + response
              response = (Utils::TextProcessing.text_before_stop_word(response, /Question:/) || response).to_s.strip
              content_after_ticks = response.split(/```json/, 2).last
              content_between_ticks = content_after_ticks&.split(/```/, 2)&.first

              Gitlab::Json.parse(content_between_ticks&.strip.to_s).with_indifferent_access
            end

            def identify_epic(resource_identifier_type, resource_identifier)
              return context.resource if current_resource?(resource_identifier_type, resource_name)

              epic = case resource_identifier_type
                     when 'iid'
                       by_iid(resource_identifier)
                     when 'url', 'reference'
                       extract_epic(resource_identifier)
                     end

              epic if Utils::Authorizer.resource_authorized?(resource: epic, user: context.current_user)
            end

            def by_iid(resource_identifier)
              return unless group_from_context

              epics = group_from_context.epics.iid_in(resource_identifier.to_i)

              return epics.first if epics.one?
            end

            def extract_epic(text)
              project = extract_project
              return unless project

              extractor = Gitlab::ReferenceExtractor.new(project, context.current_user)
              extractor.analyze(text, {})
              epics = extractor.epics

              epics.first if epics.one?
            end

            def extract_project
              return projects_from_context.first unless projects_from_context.blank?

              # Epics belong to a group. The `ReferenceExtractor` expects a `project`
              # but does not use it for the extraction of epics.
              context.current_user.authorized_projects.first
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
              content = "You already have identified the epic #{resource.to_global_id}, read carefully."
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
