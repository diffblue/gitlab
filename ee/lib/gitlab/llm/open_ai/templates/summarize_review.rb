# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module Templates
        class SummarizeReview
          SYSTEM_CONTENT = "You are a sophisticated code review assistant."
          DRAFT_NOTE_CONTEXT = <<-TEMPLATE
You are acting as the reviewer for this merge request and MUST respond in first person as if you reviewed it and should always use 'I'. You are provided with the corresponding code comment. Use this information to create an overall summary which MUST mention the types of comments left, a comment can be either: question or recommendation. This summary MUST NOT be longer than 3 sentences. This summary MUST give an indication of the topics the review covered. The summary MUST be written in present simple tense and MUST be as concise as possible. The summary MUST also include an estimate of the overall work needed, using any of the following: "small amount of work, decent amount or significant work required" but the comment MUST make sure to note this is only an estimate, for example, "I estimate there is...". Code review comments:
          TEMPLATE

          def self.get_options(draft_notes_content)
            {
              messages: [
                { role: "system", content: SYSTEM_CONTENT },
                { role: "user", content: "#{DRAFT_NOTE_CONTEXT}\n\n#{draft_notes_content}" }
              ],
              temperature: 0.2
            }
          end
        end
      end
    end
  end
end
