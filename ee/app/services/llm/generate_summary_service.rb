# frozen_string_literal: true

module Llm
  class GenerateSummaryService < BaseService
    SUPPORTED_ISSUABLE_TYPES = %w[issue work_item merge_request epic].freeze

    private

    def perform
      ::Llm::CompletionWorker.perform_async(user.id, resource.id, resource.class.name, :summarize_comments)
    end

    def valid?
      super &&
        SUPPORTED_ISSUABLE_TYPES.include?(resource.to_ability_name) &&
        Feature.enabled?(:summarize_comments, resource.resource_parent) &&
        !resource.notes.for_summarize_by_ai.empty?
    end
  end
end
