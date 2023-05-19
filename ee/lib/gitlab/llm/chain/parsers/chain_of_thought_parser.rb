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
            parse_thought
            parse_final_answer
          end

          private

          def parse_action
            /Action\s*\d*\s*:\s*(?<action>.*?)\s*Action\s*\d*\s*Input\s*\d*\s*:\s*(?<action_input>.*)/ =~ output

            @action = action&.strip
            @action_input = action_input&.strip
          end

          def parse_thought
            /Thought: (?<thought>.+?)(?=Action|Final Answer)/m =~ output

            @thought = thought&.strip
          end

          def parse_final_answer
            /Final Answer: (?<final_answer>.+)/m =~ output

            @final_answer = final_answer&.strip
          end
        end
      end
    end
  end
end
