# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module Templates
        class SummarizeAllOpenNotes
          def self.get_prompt(content)
            prompt = <<-TEMPLATE
              Create a markdown header with main text idea followed by a summary of the following text, in at most 10 bullet points:
              """
              #{content}
              """
            TEMPLATE

            {
              method: :completions,
              prompt: prompt,
              options: {
                temperature: 0.2
              }
            }
          end
        end
      end
    end
  end
end
