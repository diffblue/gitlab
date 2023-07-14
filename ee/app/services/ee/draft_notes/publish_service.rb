# frozen_string_literal: true

module EE
  module DraftNotes
    module PublishService
      def after_publish(review)
        Llm::SummarizeSubmittedReviewService
          .new(
            current_user,
            merge_request,
            review_id: review.id,
            diff_id: merge_request.latest_merge_request_diff_id
          )
          .execute
      end
    end
  end
end
