# frozen_string_literal: true

module Llm
  class GenerateSummaryService < BaseService
    SUPPORTED_ISSUABLE_TYPES = %w[issue epic].freeze

    private

    def perform
      perform_async(user, resource, :summarize_comments, options)
    end

    def valid?
      super &&
        SUPPORTED_ISSUABLE_TYPES.include?(resource.to_ability_name) &&
        Ability.allowed?(user, :summarize_notes, resource) &&
        !resource.notes.for_summarize_by_ai.empty?
    end
  end
end
