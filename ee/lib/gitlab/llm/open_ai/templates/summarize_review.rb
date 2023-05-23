# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module Templates
        class SummarizeReview
          SYSTEM_CONTENT = "You are a sophisticated code review assistant."
          DRAFT_NOTE_CONTEXT = <<-TEMPLATE
            You are creating an action list for the code author. You are provided with pairs of file path and a corresponding code comment. Filter these pairs to exclude any praise comments or anything unrelated to code review. Then use that to create a concise high level summary of the code review and present it as an action list for the reviewer in Markdown. DO NOT create any titles in the result. Provide a result in this format ONLY: \"Here's a quick summary of the code review:\n<action list>\"
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
