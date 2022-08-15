# frozen_string_literal: true

module EE
  module MergeRequests
    module UpdateAssigneesService
      def assignee_ids
        if project.licensed_feature_available?(:multiple_merge_request_assignees)
          filter_sentinel_values(params.fetch(:assignee_ids))
        else
          super
        end
      end
    end
  end
end
