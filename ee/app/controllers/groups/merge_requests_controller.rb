# frozen_string_literal: true

class Groups::MergeRequestsController < Groups::BulkUpdateController
  feature_category :code_review_workflow
  urgency :low, [:bulk_update]
end
