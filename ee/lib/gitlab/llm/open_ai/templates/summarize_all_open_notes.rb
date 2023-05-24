# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module Templates
        class SummarizeAllOpenNotes
          def self.get_options(notes_content)
            num = Random.rand(100..999)
            system_content = <<-TEMPLATE
              You are an assistant that extracts the most important information from the comments in maximum 10 bullet points.
              Comments are between two identical sets of 3-digit numbers surrounded by < > sign.

              <#{num}>
              #{notes_content}
              <#{num}>

              Desired markdown format:
              ## <summary_title>
              <bullet_points>
              """

              Focus on extracting information related to one another and that are the majority of the content.
              Ignore phrases that are not connected to others.
              Do not specify what you are ignoring.
              Do not answer questions.
            TEMPLATE

            {
              content: system_content,
              temperature: 0.2
            }
          end
        end
      end
    end
  end
end
