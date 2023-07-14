# frozen_string_literal: true

module Llm
  class SummarizeSubmittedReviewService < ::Llm::BaseService
    private

    def perform
      worker_perform(user, resource, :summarize_submitted_review, options)
    end

    def valid?
      super &&
        resource.to_ability_name == "merge_request" &&
        Ability.allowed?(user, :summarize_submitted_review, resource)
    end
  end
end
