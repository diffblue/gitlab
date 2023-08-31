# frozen_string_literal: true

module EE
  module MergeRequests
    module CreateRefService
      extend ::Gitlab::Utils::Override

      private

      override :update_merge_request!
      def update_merge_request!(merge_request, result)
        merge_request.merge_params['train_ref'] =
          result
            .slice(:commit_sha, :merge_commit_sha, :squash_commit_sha)
            .stringify_keys

        merge_request.save!
      rescue StandardError => e
        ::Gitlab::ErrorTracking.track_exception(e)
        raise ::MergeRequests::CreateRefService::CreateRefError, "Failed to update merge params"
      end

      override :merge_commit_message
      def merge_commit_message
        legacy_commit_message || super
      end

      def legacy_commit_message
        return if ::Feature.enabled?(:standard_merge_train_ref_merge_commit, target_project)

        ::MergeTrains::MergeCommitMessage.legacy_value(merge_request, first_parent_ref)
      end
    end
  end
end
