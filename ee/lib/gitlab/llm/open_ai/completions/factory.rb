# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module Completions
        class Factory
          COMPLETIONS = {
            explain_vulnerability: {
              service_class: ::Gitlab::Llm::OpenAi::Completions::ExplainVulnerability,
              prompt_class: ::Gitlab::Llm::OpenAi::Templates::ExplainVulnerability
            },
            summarize_comments: {
              service_class: ::Gitlab::Llm::OpenAi::Completions::SummarizeAllOpenNotes,
              prompt_class: ::Gitlab::Llm::OpenAi::Templates::SummarizeAllOpenNotes
            },
            explain_code: {
              service_class: ::Gitlab::Llm::OpenAi::Completions::ExplainCode,
              prompt_class: ::Gitlab::Llm::OpenAi::Templates::ExplainCode
            },
            tanuki_bot: {
              service_class: ::Gitlab::Llm::OpenAi::Completions::TanukiBot,
              prompt_class: ::Gitlab::Llm::OpenAi::Templates::TanukiBot
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
