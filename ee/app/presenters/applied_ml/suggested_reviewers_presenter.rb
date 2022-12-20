# frozen_string_literal: true
#
module AppliedMl
  class SuggestedReviewersPresenter < Gitlab::View::Presenter::Delegated
    presents ::MergeRequest::Predictions, as: :predictions

    delegator_override :accepted
    def accepted
      accepted_reviewer_usernames
    end

    delegator_override :suggested
    def suggested
      suggested_reviewer_usernames
    end
  end
end
