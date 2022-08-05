# frozen_string_literal: true

module EE
  module MergeRequests
    module UpdateReviewersService
      extend ::Gitlab::Utils::Override

      override :reviewer_ids
      def reviewer_ids
        if project.licensed_feature_available?(:multiple_merge_request_reviewers)
          filter_sentinel_values(params.fetch(:reviewer_ids))
        else
          super
        end
      end
    end
  end
end
