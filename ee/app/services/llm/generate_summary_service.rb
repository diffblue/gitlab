# frozen_string_literal: true

module Llm
  class GenerateSummaryService < BaseService
    SUPPORTED_ISSUABLE_TYPES = %w[issue epic].freeze

    private

    def perform
      ::Llm::CompletionWorker.perform_async(user.id, resource.id, resource.class.name, :summarize_comments)
      success
    end

    def valid?
      super &&
        SUPPORTED_ISSUABLE_TYPES.include?(resource.to_ability_name) &&
        Ability.allowed?(user, :summarize_notes, resource) &&
        !resource.notes.for_summarize_by_ai.empty?
    end
  end
end
