# frozen_string_literal: true

module MergeRequests
  class CaptureSuggestedReviewersAcceptedService < BaseProjectService
    # Capture suggested reviewers whom are accepted as reviewers
    #
    # @param [MergeRequest] merge_request
    # @param [Array] reviewer_ids
    #
    # The list of accepted users will be normalised with the suggested list and
    # existing accepted list.
    #
    #   suggested_usernames: [a, b, c]
    #   existing_accepted_usernames: [a]
    #   new_accepted_usernames: [b, d]
    #   accepted_usernames: [a, b]
    #
    # @return [ServiceResponse] an instance of a ServiceResponse object
    def execute(merge_request, reviewer_ids)
      return ServiceResponse.error(message: 'Reviewer IDs are empty') if reviewer_ids.blank?
      return ServiceResponse.error(message: 'Merge request is not eligible') unless merge_request.can_suggest_reviewers?

      predictions = merge_request.predictions
      return ServiceResponse.error(message: 'No predictions are recorded') if predictions.blank?

      accepted_usernames = calculate_accepted_usernames(predictions, reviewer_ids)
      predictions.update!(accepted_reviewers: { reviewers: accepted_usernames })

      ServiceResponse.success(
        payload: {
          project_id: project.id,
          merge_request_id: merge_request.id,
          reviewers: predictions.accepted_reviewer_usernames
        }
      )
    rescue ActiveRecord::RecordInvalid => err
      ServiceResponse.error(message: err.message)
    end

    private

    def calculate_accepted_usernames(predictions, reviewer_ids)
      suggested_usernames = predictions.suggested_reviewer_usernames
      existing_accepted_usernames = predictions.accepted_reviewer_usernames
      new_accepted_usernames = project.member_usernames_among(User.id_in(reviewer_ids))

      suggested_usernames & (existing_accepted_usernames | new_accepted_usernames)
    end
  end
end
