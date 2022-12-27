# frozen_string_literal: true

module EE
  module PolicyActor
    def auditor?
      false
    end

    def visual_review_bot?
      false
    end

    def suggested_reviewers_bot?
      false
    end

    def group_sso?(_)
      false
    end
  end
end
