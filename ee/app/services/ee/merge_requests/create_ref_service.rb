# frozen_string_literal: true

module EE
  module MergeRequests
    module CreateRefService
      extend ::Gitlab::Utils::Override

      private

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
