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
          elsif merge_request.missing_required_squash?
            'This project requires squashing commits when merge requests are accepted.'
          elsif mr_not_mergable?
            'Merge request is not mergeable'
          elsif source_sha != repository.commit(merge_request.train_ref_path)&.sha
            'Merge source out-of-date.'
          end

        raise ::MergeRequests::MergeStrategies::StrategyError, error_message if error_message
      end

      def execute_git_merge!
        commit_sha = repository.ff_merge(
          current_user,
          source_sha,
          merge_request.target_branch,
          merge_request: merge_request
        )

        result = { commit_sha: commit_sha }

        # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/422483
        #
        # This section below is a hack until we persist the correct values when the
        # ref is created.
        #
        # We can get an incorrect merge_commit_sha or squash_commit_sha if the
        # merge request's squash preference, or the project's merge method
        # preferences, have changed since the ref was created.
        if merge_request.squash_on_merge?
          if merge_request.project.merge_requests_ff_only_enabled
            # There is no merge commit, so the squash commit is just the commit.
            result[:squash_commit_sha] = commit_sha
          else
            # By construction, the second parent of the merge commit is the
            # final SHA of the source as it landed on the target branch. This is
            # therefore the squash commit SHA.
            merge_commit = project.repository.commit(commit_sha)
            _, squash_commit_sha = merge_commit.parent_ids
            result[:squash_commit_sha] = squash_commit_sha
          end
        end

        # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/422483
        result[:merge_commit_sha] = commit_sha unless merge_request.project.merge_requests_ff_only_enabled

        result
      end

      private

      delegate :repository, to: :project

      attr_reader :merge_request, :current_user, :merge_params, :options, :project, :source_sha

      def mr_not_mergable?
        !merge_request.mergeable?(
          skip_discussions_check: options[:skip_discussions_check],
          check_mergeability_retry_lease: options[:check_mergeability_retry_lease],
          skip_rebase_check: true
        )
      end
    end
  end
end
