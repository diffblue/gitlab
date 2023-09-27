# frozen_string_literal: true
module MergeTrains
  class RefreshMergeRequestService < BaseService
    include Gitlab::Utils::StrongMemoize

    ProcessError = Class.new(StandardError)

    attr_reader :merge_request

    ##
    # Arguments:
    # merge_request ... The merge request to be refreshed
    def execute(merge_request)
      @merge_request = merge_request

      validate!
      pipeline_created = create_pipeline! if merge_train_car.requires_new_pipeline? || require_recreate?
      merge! if merge_train_car.mergeable?

      success(pipeline_created: pipeline_created.present?)
    rescue ProcessError => e
      abort(e)
    end

    private

    def validate!
      unless project.merge_trains_enabled?
        raise ProcessError, 'project disabled merge trains'
      end

      unless merge_request.on_train?
        raise ProcessError, 'merge request is not on a merge train'
      end

      if !merge_request.open? || merge_request.broken? || merge_request.draft?
        raise ProcessError, 'merge request is not mergeable'
      end

      unless merge_train_car.previous_ref_sha.present?
        raise ProcessError, 'previous ref does not exist'
      end

      if merge_train_car.pipeline_not_succeeded?
        raise ProcessError, 'pipeline did not succeed'
      end
    end

    def merge_from_train_ref?
      # For now, we only enable this for fast-forward merge trains
      return false unless project.merge_requests_ff_only_enabled && Feature.enabled?(:fast_forward_merge_trains_support, project)

      mergeable_sha_and_message?(merge_train_car)
    end

    def create_mergeable_train_ref?
      # These two flags being enabled are pre-requisites
      unless Feature.enabled?(:merge_trains_create_ref_service, merge_request.target_project) &&
          Feature.enabled?(:standard_merge_train_ref_merge_commit, merge_request.target_project)
        return false
      end

      # The two checks below ensure that by construction, we can safely
      # fast-forward merge from any train ref satisfying
      # #mergeable_from_train_ref?
      #
      # (1) Base case: If we're the first car, then the train ref will be based
      # on the target branch, and is trivially mergeable.
      return true if merge_train_car.first_car?

      # (2) Recursive case: The previous MR has not been merged, so we check
      # whether it was constructed with a mergeable train ref.
      mergeable_sha_and_message?(merge_train_car.prev)
    end

    def mergeable_sha_and_message?(car)
      # The commit message check guards against a very unlikely edge case in
      # which a merge train created by MergeTrains::CreateRefService has been
      # running since before standard merge commits were first enabled, and no
      # merge has occurred.
      #
      # The train_ref commit_sha check is for mixed rollout scenarios, such as
      # when the various feature flags are toggled, or when old code is running
      # concurrently with new code, or when a train exists from before the
      # instance was updated.
      sha = car.pipeline&.sha
      project.commit(sha)&.message != MergeTrains::MergeCommitMessage.legacy_value(merge_request, car.previous_ref) &&
        sha == car&.merge_request&.merge_params&.dig('train_ref', 'commit_sha')
    end

    def create_pipeline!
      result = MergeTrains::CreatePipelineService.new(merge_train_car.project, merge_train_car.user)
        .execute(merge_train_car.merge_request, merge_train_car.previous_ref, create_mergeable_train_ref?)

      raise ProcessError, result[:message] unless result[:status] == :success

      pipeline = result[:pipeline]
      cancel_pipeline!(merge_train_car.pipeline, pipeline.id)
      merge_train_car.refresh_pipeline!(pipeline.id)

      pipeline
    end

    def cancel_pipeline!(pipeline, new_pipeline_id)
      ::Ci::CancelPipelineService
        .new(pipeline: pipeline, current_user: nil, auto_canceled_by_pipeline_id: new_pipeline_id)
        .force_execute
    rescue ActiveRecord::StaleObjectError
      # Often the pipeline has already been canceled by the auto-cancellation
      # mechanism when new pipelines for the same ref are created.
      # In this case, we can ignore the exception as it's already canceled.
    end

    def merge!
      merge_train_car.start_merge!

      merge_options = { skip_discussions_check: true, check_mergeability_retry_lease: true }
      merge_options[:merge_strategy] = MergeRequests::MergeStrategies::FromTrainRef if merge_from_train_ref?

      MergeRequests::MergeService.new(project: project, current_user: merge_user, params: merge_request.merge_params.with_indifferent_access)
        .execute(merge_request, **merge_options)

      raise ProcessError, "failed to merge. #{merge_request.merge_error}" unless merge_request.merged?

      merge_train_car.finish_merge!
    end

    def merge_train_car
      merge_request.merge_train_car
    end

    def merge_user
      merge_request.merge_user
    end

    def require_recreate?
      params[:require_recreate]
    end

    def abort(error)
      AutoMerge::MergeTrainService.new(project, merge_user)
        .abort(merge_request, error.message, process_next: false)

      error(error.message)
    end
  end
end
