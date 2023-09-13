# frozen_string_literal: true

module MergeRequests
  module MergeStrategies
    # Merges a merge request on a merge train. It does a git fast-forward merge
    # of the merge train ref into the target ref, and returns the commit SHAs
    # required for tracking.
    #
    # IMPORTANT! The merge train ref must be constructed to be exactly like the
    # desired target branch. Otherwise, this operation is not safe.
    class FromTrainRef
      include Gitlab::Utils::StrongMemoize

      def initialize(merge_request, current_user, merge_params: {}, options: {})
        @merge_request = merge_request
        @current_user = current_user
        @project = merge_request.project
        @merge_params = merge_params
        @options = options
        @source_sha = merge_request&.merge_train_car&.pipeline&.sha
      end

      def validate!
        error_message =
          if source_sha.blank?
            'No source for merge'
          elsif not_mergable?
            'Merge request is not mergeable'
          elsif missing_squash_commit_sha?
            'Outdated merge train: Squash commit SHA missing.'
          elsif unexpected_squash_commit_sha?
            'Outdated merge train: Unexpected commit SHA in train ref parameters.'
          elsif outdated_source_sha?
            'Outdated merge train: Merge source out-of-date.'
          end

        raise ::MergeRequests::MergeStrategies::StrategyError, error_message if error_message
      end

      def execute_git_merge!
        repository.ff_merge(
          current_user,
          source_sha,
          merge_request.target_branch,
          merge_request: merge_request
        )

        # Since this is a fast-forward merge, the commit SHAs are exactly what
        # is in train_ref_merge_params
        train_ref_merge_params
      end

      private

      delegate :repository, to: :project

      attr_reader :merge_request, :current_user, :merge_params, :options, :project, :source_sha

      def train_ref_merge_params
        merge_request.merge_params.with_indifferent_access['train_ref']&.symbolize_keys || {}
      end
      strong_memoize_attr :train_ref_merge_params

      def missing_squash_commit_sha?
        # This can happen if the merge request's squash attribute is changed
        # after starting the Auto Merge.
        merge_request.squash? && train_ref_merge_params[:squash_commit_sha].blank?
      end

      def unexpected_squash_commit_sha?
        # This can happen if the merge request's squash attribute is changed
        # after starting the Auto Merge.
        !merge_request.squash? && train_ref_merge_params[:squash_commit_sha].present?
      end

      def outdated_source_sha?
        # This guard against a races where the train ref is updated by another
        # process during the merge. This complements the mergability check,
        # which should cover changes in the source branch.
        source_sha != repository.commit(merge_request.train_ref_path)&.sha ||
          source_sha != train_ref_merge_params[:commit_sha]
      end

      def not_mergable?
        !merge_request.mergeable?(
          skip_discussions_check: options[:skip_discussions_check],
          check_mergeability_retry_lease: options[:check_mergeability_retry_lease],
          skip_rebase_check: true
        )
      end
    end
  end
end
