# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      class StreamedAnswer
        def initialize
          self.final_answer_started = false
          self.id = 0
          self.full_message = ""
        end

        def next_chunk(content)
          # If it already contains the final answer, we can return the content directly.
          # There is then also no longer the need to build the full message.
          return payload(content) if final_answer_started

          self.full_message += content

          return unless final_answer_start.present?

          self.final_answer_started = true
          payload(final_answer_start.lstrip)
        end

        private

        attr_accessor :full_message, :id, :final_answer_started

        def payload(content)
          self.id += 1

          { content: content, id: id }
        end

        # The ChainOfThoughtParser would treat a response without any "Final Answer:" in the response
        # as an answer. Because we do not have the full response when parsing the stream, we need to rely
        # on the fact that everything after "Final Answer:" will be the final answer.
        def final_answer_start
          /Final Answer:(?<final_answer>.+)/m =~ full_message

          final_answer
        end
      end
    end
  end
end
