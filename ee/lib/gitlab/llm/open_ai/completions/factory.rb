# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module Completions
        class Factory
          COMPLETIONS = {
            summarize_comments: {
              service_class: ::Gitlab::Llm::OpenAi::Completions::SummarizeAllOpenNotes,
              prompt_class: ::Gitlab::Llm::OpenAi::Templates::SummarizeAllOpenNotes
            }
          }.freeze

          def self.completion(name)
            return unless COMPLETIONS.key?(name)

            service_class, prompt_class = COMPLETIONS[name].values_at(:service_class, :prompt_class)
            service_class.new(prompt_class)
          end
        end
      end
    end
  end
end
