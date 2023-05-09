# frozen_string_literal: true

module Gitlab
  module Llm
    class CompletionsFactory
      COMPLETIONS = {
        explain_vulnerability: {
          service_class: ::Gitlab::Llm::VertexAi::Completions::ExplainVulnerability,
          prompt_class: ::Gitlab::Llm::Templates::ExplainVulnerability
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
        },
        generate_test_file: {
          service_class: ::Gitlab::Llm::OpenAi::Completions::GenerateTestFile,
          prompt_class: ::Gitlab::Llm::OpenAi::Templates::GenerateTestFile
        },
        generate_description: {
          service_class: ::Gitlab::Llm::OpenAi::Completions::GenerateDescription,
          prompt_class: ::Gitlab::Llm::OpenAi::Templates::GenerateDescription
        }
      }.freeze

      def self.completion(name, params = {})
        return unless COMPLETIONS.key?(name)

        service_class, prompt_class = COMPLETIONS[name].values_at(:service_class, :prompt_class)
        service_class.new(prompt_class, params)
      end
    end
  end
end
