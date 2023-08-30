# frozen_string_literal: true

module MergeTrains
  module MergeCommitMessage
    # Remove with merge_trains_create_ref_service
    # and standard_merge_train_ref_merge_commit flag
    def self.legacy_value(merge_request, previous_ref)
      "Merge branch #{merge_request.source_branch} with #{previous_ref} " \
        "into #{merge_request.train_ref_path}"
    end
  end
end
