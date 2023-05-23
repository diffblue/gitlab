# frozen_string_literal: true

module Llm
  module MergeRequests
    class SummarizeReviewService < ::Llm::BaseService
      private

      def perform
        perform_async(user, resource, :summarize_review, options)
      end

      def valid?
        super &&
          resource.to_ability_name == "merge_request" &&
          resource.draft_notes.authored_by(user).any? &&
          Ability.allowed?(user, :summarize_draft_code_review, resource)
      end
    end
  end
end
