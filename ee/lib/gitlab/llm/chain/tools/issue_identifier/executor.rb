# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module IssueIdentifier
          class Executor < Identifier
            RESOURCE_NAME = 'issue'
            NAME = "IssueIdentifier"
            HUMAN_NAME = 'Issue Search'
            DESCRIPTION = 'Useful tool when you need to identify a specific issue. ' \
                          'Do not use this tool if you have already identified the issue.' \
                          'In this context, word `issue` means core building block in GitLab that enable ' \
                          'collaboration, discussions, planning and tracking of work.' \
                          'Action Input for this tool should be the original question or issue identifier.'

            EXAMPLE =
              <<~PROMPT
                Question: Please identify the author of #issue_identifier issue
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
                An issue can also be referenced by a GitLab reference.
                A GitLab reference ends with a number preceded by the delimiter # and contains one or more /.
                ResourceIdentifierType can only be one of [current, iid, url, reference]
                ResourceIdentifier can be number, url. If ResourceIdentifier is not a number or a url
                use "current".
                When you see a GitLab reference, ResourceIdentifierType should be reference.

                Make sure the response is a valid JSON. The answer should be just the JSON without any other commentary!
                References in the given question to the current issue can be also for example "this issue" or "that issue",
                referencing the issue that the user currently sees.
                Question: (the user question)
                Response (follow the exact JSON response):
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
                  "ResourceIdentifier": "current"
                }
                ```

                Begin!
                PROMPT
              ),
              Utils::Prompt.as_assistant("%<suggestions>s"),
              Utils::Prompt.as_user("Question: %<input>s")
            ].freeze

            private

            def reference_pattern_by_type
              PROJECT_REGEX
            end

            def prompt_template
              PROMPT_TEMPLATE
            end

            def by_iid(resource_identifier)
              return unless projects_from_context

              issues = Issue.in_projects(projects_from_context).iid_in(resource_identifier.to_i)

              return issues.first if issues.one?
            end

            def extract_resource(text, type)
              project = extract_project(text, type)
              return unless project

              extractor = Gitlab::ReferenceExtractor.new(project, context.current_user)
              extractor.analyze(text, {})
              issues = extractor.issues

              return issues.first if issues.one?
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
