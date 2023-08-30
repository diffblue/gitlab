# frozen_string_literal: true

module Gitlab
  module Llm
    class CompletionsFactory
      COMPLETIONS = {
        explain_vulnerability: {
          service_class: ::Gitlab::Llm::Completions::ExplainVulnerability,
          prompt_class: ::Gitlab::Llm::Templates::ExplainVulnerability,
          feature_category: :vulnerability_management
        },
        summarize_comments: {
          service_class: ::Gitlab::Llm::Completions::SummarizeAllOpenNotes,
          prompt_class: nil,
          feature_category: :ai_abstraction_layer
        },
        summarize_review: {
          service_class: ::Gitlab::Llm::VertexAi::Completions::SummarizeReview,
          prompt_class: ::Gitlab::Llm::Templates::SummarizeReview,
          feature_category: :ai_abstraction_layer
        },
        explain_code: {
          service_class: ::Gitlab::Llm::VertexAi::Completions::ExplainCode,
          prompt_class: ::Gitlab::Llm::VertexAi::Templates::ExplainCode,
          feature_category: :ai_abstraction_layer
        },
        explain_code_open_ai: {
          service_class: ::Gitlab::Llm::OpenAi::Completions::ExplainCode,
          prompt_class: ::Gitlab::Llm::OpenAi::Templates::ExplainCode,
          feature_category: :code_review_workflow
        },
        tanuki_bot: {
          service_class: ::Gitlab::Llm::Anthropic::Completions::TanukiBot,
          prompt_class: ::Gitlab::Llm::Anthropic::Templates::TanukiBot,
          feature_category: :ai_abstraction_layer
        },
        generate_test_file: {
          service_class: ::Gitlab::Llm::VertexAi::Completions::GenerateTestFile,
          prompt_class: ::Gitlab::Llm::Templates::GenerateTestFile,
          feature_category: :code_review_workflow
        },
        generate_description: {
          service_class: ::Gitlab::Llm::OpenAi::Completions::GenerateDescription,
          prompt_class: ::Gitlab::Llm::OpenAi::Templates::GenerateDescription,
          feature_category: :ai_abstraction_layer
        },
        generate_commit_message: {
          service_class: ::Gitlab::Llm::VertexAi::Completions::GenerateCommitMessage,
          prompt_class: ::Gitlab::Llm::Templates::GenerateCommitMessage,
          feature_category: :code_review_workflow
        },
        analyze_ci_job_failure: {
          service_class: Gitlab::Llm::VertexAi::Completions::AnalyzeCiJobFailure,
          prompt_class: nil,
          feature_category: :continuous_integration
        },
        chat: {
          service_class: ::Gitlab::Llm::Completions::Chat,
          prompt_class: nil,
          feature_category: :duo_chat
        },
        fill_in_merge_request_template: {
          service_class: ::Gitlab::Llm::VertexAi::Completions::FillInMergeRequestTemplate,
          prompt_class: ::Gitlab::Llm::Templates::FillInMergeRequestTemplate,
          feature_category: :code_review_workflow
        },
        summarize_submitted_review: {
          service_class: ::Gitlab::Llm::VertexAi::Completions::SummarizeSubmittedReview,
          prompt_class: ::Gitlab::Llm::Templates::SummarizeSubmittedReview,
          feature_category: :code_review_workflow
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

::Gitlab::Llm::CompletionsFactory.prepend_mod
