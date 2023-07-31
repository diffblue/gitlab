# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module JsonReader
          class Executor < Tool
            include Concerns::AiDependent

            PromptRoles = ::Gitlab::Llm::Chain::Utils::Prompt
            TextUtils = Gitlab::Llm::Chain::Utils::TextProcessing

            NAME = 'ResourceReader'
            DESCRIPTION = 'Useful tool when you need to get information about specific resource ' \
                          'that was already identified. ' \
                          'Action Input for this tools always starts with: `data`'
            EXAMPLE =
              <<~PROMPT
                Question: Who is an author of this issue
                Picked tools: First: "IssueIdentifier" tool, second: "ResourceReader" tool.
                Reason: You have access to the same resources as user who asks a question.
                  Once the resource is identified, you should use "ResourceReader" tool to fetch relevant information
                  about the resource. Based on this information you can present final answer.
              PROMPT

            MAX_RETRIES = 3

            PROVIDER_PROMPT_CLASSES = {
              anthropic: ::Gitlab::Llm::Chain::Tools::JsonReader::Prompts::Anthropic,
              vertex_ai: ::Gitlab::Llm::Chain::Tools::JsonReader::Prompts::VertexAi
            }.freeze

            def initialize(context:, options:)
              super
              @retries = 0
            end

            def execute
              # We need to implement it on all models we want to take into considerations
              unless resource.respond_to?(:serialize_for_ai)
                return Answer.error_answer(context: context,
                  content: _("Unexpected error: Cannot serialize resource", resource_class: resource.class)
                )
              end

              resource_json = resource.serialize_for_ai(
                user: context.current_user,
                content_limit: provider_prompt_class::MAX_CHARACTERS
              ).to_json
              # todo: not ideal as we load the entire json into memory,
              # todo: follow-up: https://gitlab.com/gitlab-org/gitlab/-/issues/414848
              @data = Gitlab::Json.parse(resource_json)

              options[:suggestions] = options[:suggestions].to_s
              prompt_length = resource_json.length + options[:suggestions].length

              if prompt_length < provider_prompt_class::MAX_CHARACTERS
                process_short_path(resource_json)
              else
                process_long_path
              end
            rescue StandardError => e
              logger.error(message: "error message", error: e.message)
              Answer.error_answer(context: context, content: _("Unexpected error"))
            end

            private

            attr_accessor :data, :retries

            def process_short_path(resource_json)
              content = "Please use this information about this resource: #{resource_json}"
              ::Gitlab::Llm::Chain::Answer.new(status: :ok, context: context, content: content, tool: nil)
            end

            def process_long_path
              failure_message = "#{options[:suggestions]}\nFailed to parse JSON."
              return Answer.error_answer(context: context, content: failure_message) if retries >= MAX_RETRIES

              parser = Parsers::ChainOfThoughtParser.new(output: request)
              parser.parse

              tool_answer = Answer.new(status: :ok, context: context, content: parser.final_answer, tool: nil)
              return tool_answer if parser.final_answer

              options[:suggestions] << "\nAction: #{parser.action}\nAction Input: #{parser.action_input}\n"
              options[:suggestions] << "\nThought:#{parser.thought}" unless parser.thought.blank?

              action_class = case parser.action
                             when /.*JsonReaderListKeys.*/
                               Utils::JsonReaderListKeys
                             when /.*JsonReaderGetValue.*/
                               Utils::JsonReaderGetValue
                             end

              if action_class
                json_keys = action_class.handle_keys(parser.action_input, data).to_json
                options[:suggestions] << "\nObservation: #{json_keys}\n"
              else
                self.retries += 1
                msg = "#{action_class} is not valid, Action must be either `JsonReaderListKeys` or `JsonReaderGetValue`"
                options[:suggestions] << "\nObservation: #{msg}"
              end

              process_long_path
            rescue JSON::ParserError
              # try to help out AI to fix the JSON format by adding the error as an observation
              self.retries += 1
              error_message = "\nObservation: JSON has an invalid format. Please retry."
              options[:suggestions] += error_message

              process_long_path
            end

            def build_prompt(options)
              prompt = PROMPT_TEMPLATE.map(&:last).join("\n").concat("\nThought:")
              format(prompt.to_s, input: options, suggestions: options[:suggestions])
            end

            # rubocop: disable Layout/LineLength
            # our template
            PROMPT_TEMPLATE = [
              PromptRoles.as_system(
                <<~PROMPT
                  You are an agent designed to interact with JSON.
                  Your goal is to return a information relevant to make final answer as JSON.
                  You have access to the following tools which help you learn more about the JSON you are interacting with.
                  Only use the below tools. Only use the information returned by the below tools to construct your final answer.
                  Do not make up any information that is not contained in the JSON.
                  Your input to the tools should be in the form of `data['key'][0]` where `data` is the JSON blob you are interacting with, and the syntax used is Ruby.
                  You should only use keys that you know for a fact exist. You must validate that a key exists by seeing it previously when calling `JsonReaderListKeys`.
                  If you have not seen a key in one of those responses you cannot use it.
                  You should only add one key at a time to the path. You cannot add multiple keys at once.
                  If you encounter a 'KeyError', go back to the previous key, look at the available keys and try again.

                  If the question does not seem to be related to the JSON, just return 'I don't know' as the answer.
                  Always start your interaction with the `Action: JsonReaderListKeys` tool and input 'Action Input: data' to see what keys exist in the JSON.

                  Note that sometimes the value at a given path is large. In this case, you will get an error 'Value is a large dictionary, should explore its keys directly'.
                  In this case, you should ALWAYS follow up by using the `JsonReaderListKeys` tool to see what keys exist at that path.
                  Do not simply refer the user to the JSON or a section of the JSON, as this is not a valid answer. Keep digging until you find the answer and explicitly return it.


                  JsonReaderListKeys:
                      Can be used to list all keys at a given path.
                      Before calling this you should be SURE that the path to this exists.
                      The input is a text representation of the path in a Hash in Ruby syntax (e.g. data['key1'][0]['key2']).

                  JsonReaderGetValue:
                      Can be used to see value in string format at a given path.
                      Before calling this you should be SURE that the path to this exists.
                      The input is a text representation of the path in a Hash in Ruby syntax (e.g. data['key1'][0]['key2']).


                  Use the following format:

                  Question: the input question you must answer
                  Thought: you should always think about what to do
                  Action: the action to take, should be one from this list: [JsonReaderListKeys JsonReaderGetValue]
                  Action Input: the input to the action
                  Observation: the result of the action
                  ... (this Thought/Action/Action Input/Observation can repeat N times)
                  Thought: I now know the final answer
                  Final Answer: Information relevant to answering question as JSON.
                  REMEMBER to ALWAYS start a line with "Final Answer:" to give me the final answer.

                  Begin!
                PROMPT
              ),
              PromptRoles.as_user("Question: %<input>s"),
              PromptRoles.as_assistant(
                <<~PROMPT
                  Thought: I should look at the keys that exist in `data` to see what I have access to\n,
                  %<suggestions>s

                PROMPT
              )
            ].freeze
          end
          # rubocop: enable Layout/LineLength
        end
      end
    end
  end
end
