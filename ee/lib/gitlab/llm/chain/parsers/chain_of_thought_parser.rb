# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Parsers
        class ChainOfThoughtParser < OutputParser
          attr_reader :action, :action_input, :thought, :final_answer

          def parse
            @output = Utils::TextProcessing.text_before_stop_word(output) || output

            parse_action
            parse_action_input
            parse_thought
            parse_final_answer

            # this should be last (fallback) step after all parsing is done
            final_answer_from_unformatted_response
          end

          private

          # Match the first occurrence of "Action: " and capture everything until "Action Input"
          def parse_action
            /Action:(?<action>.+?)(?=Action Input:|Final Answer:)/m =~ output

            @action = action&.strip
          end

          # Match the first occurrence of "Action Input: " and capture everything until:
          # - "Observation" if it's present
          # - "Final Answer" if it's present
          # - End of string
          def parse_action_input
            /(?<=Action Input:)(?<action_input>.*?)(?=Observation|Final Answer|\z)/m =~ output

            @action_input = action_input&.strip
          end

          # Match everything before "Action:" or "Final Answer:" and remove
          # everything before and including "Thought: " if it's present
          def parse_thought
            /^(?<thought>.*?)(?=Action:|Final Answer:)/m =~ output

            @thought = thought&.sub(/.*Thought:/m, '')&.strip
          end

          # Match the first occurrence of "Final Answer: " and capture everything
          def parse_final_answer
            /Final Answer:(?<final_answer>.+)/m =~ output

            @final_answer = final_answer&.strip
          end

          # if response doesn't follow expected format, it usually means it's
          # a final answer (although there is a risk of hallucination). Such
          # response is treated as final response instead of returning "I
          # don't know"
          def final_answer_from_unformatted_response
            return if action.present? || action_input.present? || thought.present? || final_answer.present?

            answer = output.to_s.strip.sub(/\AAction: DirectAnswer\s*/, '')
            return if answer.empty?

            @final_answer = answer
          end
        end
      end
    end
  end
end
