# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module Templates
        class SummarizeAllOpenNotes
          def self.get_options(notes_content)
            system_content = <<-TEMPLATE
              You are an assistant that summarizes issue comments in maximum 10 bullet points.
              Desired markdown format:
              ## <summary_title>
              <bullet_points>
              """
            TEMPLATE

            {
              messages: [
                { role: "system", content: system_content },
                { role: "user", content: notes_content }
              ],
              temperature: 0.2
            }
          end
        end
      end
    end
  end
end
