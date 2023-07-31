# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module SummarizeComments
          class Executor < Tool
            include Concerns::AiDependent

            NAME = "SummarizeComments"
            DESCRIPTION = "This tool is useful when you need to create a summary of all notes, " \
                          "comments or discussions on a given, identified resource."
            EXAMPLE =
              <<~PROMPT
                  Question: Please summarize the http://gitlab.example/ai/test/-/issues/1 issue in the bullet points
                  Picked tools: First: "IssueIdentifier" tool, second: "SummarizeComments" tool.
                  Reason: There is issue identifier in the question, so you need to use "IssueIdentifier" tool.
                  Once the issue is identified, you should use "SummarizeComments" tool to summarize the issue.
                  For the final answer, please rewrite it into the bullet points.
              PROMPT

            PROVIDER_PROMPT_CLASSES = {
              anthropic: ::Gitlab::Llm::Chain::Tools::SummarizeComments::Prompts::Anthropic,
              vertex_ai: ::Gitlab::Llm::Chain::Tools::SummarizeComments::Prompts::VertexAi,
              open_ai: ::Gitlab::Llm::Chain::Tools::SummarizeComments::Prompts::OpenAi
            }.freeze

            PROMPT_TEMPLATE = [
              Utils::Prompt.as_system(
                <<~PROMPT
                  You are an assistant that extracts the most important information from the comments in maximum 10 bullet points.
                  Comments are between two identical sets of 3-digit numbers surrounded by < > sign.

                  <%<num>s>
                  %<notes_content>s
                  <%<num>s>

                  Desired markdown format:
                  **<summary_title>**
                  <bullet_points>
                  """

                  Focus on extracting information related to one another and that are the majority of the content.
                  Ignore phrases that are not connected to others.
                  Do not specify what you are ignoring.
                  Do not answer questions.
                PROMPT
              )
            ].freeze

            def perform
              return wrong_resource unless resource.is_a?(::Noteable)

              notes = NotesFinder.new(context.current_user, target: resource).execute.by_humans

              content = if notes.exists?
                          notes_content = notes_to_summarize(notes) # rubocop: disable CodeReuse/ActiveRecord
                          options[:notes_content] = notes_content
                          options[:num] = Random.rand(100..999)

                          build_answer(resource, request)
                        else
                          "#{resource_name} ##{resource.iid} has no comments to be summarized."
                        end

              logger.debug(message: "Answer", class: self.class.to_s, content: content)

              ::Gitlab::Llm::Chain::Answer.new(
                status: :ok, context: context, content: content, tool: nil, is_final: false
              )
            end

            private

            def notes_to_summarize(notes)
              notes_content = +""
              notes.each_batch do |batch|
                batch.pluck(:id, :note).each do |note| # rubocop: disable CodeReuse/ActiveRecord
                  input_content_limit = provider_prompt_class::INPUT_CONTENT_LIMIT

                  break notes_content if notes_content.size + note[1].size >= input_content_limit

                  notes_content << note[1]
                end
              end

              notes_content
            end

            def can_summarize?
              logger.debug(message: "Supported Issuable Typees Ability Allowed",
                content: Ability.allowed?(context.current_user, :summarize_notes, context.resource))
              ::Llm::GenerateSummaryService::SUPPORTED_ISSUABLE_TYPES.include?(resource.to_ability_name) &&
                Ability.allowed?(context.current_user, :summarize_notes, context.resource)
            end

            def authorize
              can_summarize? && Utils::Authorizer.context_authorized?(context: context)
            end

            def build_answer(resource, ai_response)
              return ai_response if options[:raw_ai_response]

              [
                "Here is the summary for #{resource_name} ##{resource.iid} comments:",
                ai_response.to_s
              ].join("\n")
            end

            def already_used_answer
              content = "You already have the summary of the notes, comments, discussions for the " \
                        "#{resource_name} ##{resource.iid} in your context, read carefully."

              ::Gitlab::Llm::Chain::Answer.new(
                status: :not_executed, context: context, content: content, tool: nil, is_final: false
              )
            end

            def resource
              @resource ||= context.resource
            end

            def resource_name
              @resource_name ||= resource.to_ability_name.humanize
            end
          end
        end
      end
    end
  end
end
