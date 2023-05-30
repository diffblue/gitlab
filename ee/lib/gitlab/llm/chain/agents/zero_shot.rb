# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Agents
        class ZeroShot
          attr_reader :tools, :user_input, :context
          attr_accessor :iterations

          MAX_ITERATIONS = 10

          def initialize(user_input:, tools:, context:)
            @user_input = user_input
            @tools = tools
            @context = context
            @iterations = 0
          end

          PROMPT_TEMPLATE = [
            Utils::Prompt.as_system(
              <<~PROMPT
                Answer the following questions as best you can. Start with identifying the resource first.
                You have access to the following tools:
                "%<tools_definitions>s"
                Use the following format:
                Question: the input question you must answer
                Thought: you should always think about what to do
                Action: the action to take, should be one from this list: %<tool_names>s
                Action Input: the input to the action
                Observation: the result of the actions

                ... (this Thought/Action/Action Input/Observation sequence can repeat N times)

                Thought: I know the final answer
                Final Answer: the final answer to the original input question
                Remember to start a line with "Final Answer:" to give me the final answer.

                Begin!
              PROMPT
            ),
            Utils::Prompt.as_assistant("%<agent_scratchpad>s"),
            Utils::Prompt.as_user("Question: %<user_input>s"),
            Utils::Prompt.as_assistant("Thought: ")
          ].freeze

          def execute
            MAX_ITERATIONS.times do
              response = request(prompt)
              answer = Answer.from_response(response_body: response, tools: tools, context: context)

              return answer if answer.is_final?

              input_variables[:agent_scratchpad] << answer.content.to_s << answer.suggestions.to_s
              tool = answer.tool

              tool_answer = tool.execute(
                context,
                {
                  input: user_input,
                  suggestions: input_variables[:agent_scratchpad]
                }
              )

              return tool_answer if tool_answer.is_final?

              input_variables[:agent_scratchpad] << "Observation: #{tool_answer.content}\n"
            end

            Answer.final_answer(context: context, content: Answer.default_final_answer)
          end

          private

          def prompt
            Utils::Prompt.no_role_text(PROMPT_TEMPLATE, input_variables)
          end

          def request(prompt)
            params = ::Gitlab::Llm::VertexAi::Configuration.default_payload_parameters.merge(
              temperature: 0.2
            )

            ai_client = context.ai_client
            ai_client.text(content: prompt, parameters: { **params })&.dig("predictions", 0, "content").to_s.strip
          end

          def input_variables
            @input_variables ||= {
              tool_names: tools.map(&:name),
              tools_definitions: tools.map { |tool| "#{tool.name}: #{tool.description}" }.to_s,
              user_input: user_input,
              agent_scratchpad: +""
            }
          end
        end
      end
    end
  end
end
