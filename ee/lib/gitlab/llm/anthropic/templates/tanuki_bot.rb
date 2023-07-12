# frozen_string_literal: true

module Gitlab
  module Llm
    module Anthropic
      module Templates
        class TanukiBot
          OPTIONS = {
            max_tokens: 256
          }.freeze
          CONTENT_ID_FIELD = 'ATTRS'

          def self.initial_prompt(question:, content:)
            prompt = <<~PROMPT.strip
              Use the following portion of a long document enclosed in <document></document> XML tags to see if any of the text is relevant to answer the question.
              Return any relevant text verbatim.

              <document>
              #{content}
              </document>

              Question: #{question}
              Relevant text, if any:
            PROMPT

            {
              method: :completions,
              prompt: prompt,
              options: OPTIONS
            }
          end

          def self.final_prompt(question:, documents:)
            content = documents.map do |document|
              <<~PROMPT.strip
                <quote>
                CONTENT: #{document[:extracted_text]}
                #{CONTENT_ID_FIELD}: CNT-IDX-#{document[:id]}
                </quote>
              PROMPT
            end.join("\n\n")

            prompt = <<~PROMPT.strip
              Given the following extracted parts of technical documentation enclosed in <quote></quote> XML tags and a question, create a final answer.
              If you don't know the answer, just say that you don't know. Don't try to make up an answer.
              At the end of your answer ALWAYS return a "#{CONTENT_ID_FIELD}" part for references and
              ALWAYS name it #{CONTENT_ID_FIELD}.

              QUESTION: #{question}

              #{content}

              FINAL ANSWER:
            PROMPT

            {
              method: :completions,
              prompt: prompt,
              options: OPTIONS
            }
          end
        end
      end
    end
  end
end
