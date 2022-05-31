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
      pipeline_created = create_pipeline! if merge_train.requires_new_pipeline? || require_recreate?
      merge! if merge_train.mergeable?

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

      unless merge_train.previous_ref_sha.present?
        raise ProcessError, 'previous ref does not exist'
      end

      if merge_train.pipeline_not_succeeded?
        raise ProcessError, 'pipeline did not succeed'
      end
    end

    def create_pipeline!
      result = MergeTrains::CreatePipelineService.new(merge_train.project, merge_train.user)
        .execute(merge_train.merge_request, merge_train.previous_ref)

      raise ProcessError, result[:message] unless result[:status] == :success

      pipeline = result[:pipeline]
      merge_train.cancel_pipeline!(pipeline)
      merge_train.refresh_pipeline!(pipeline.id)

      pipeline
    end

    def merge!
      merge_train.start_merge!

      MergeRequests::MergeService.new(project: project, current_user: merge_user, params: merge_request.merge_params.with_indifferent_access)
                                 .execute(merge_request, skip_discussions_check: true)

      raise ProcessError, "failed to merge. #{merge_request.merge_error}" unless merge_request.merged?

      merge_train.finish_merge!
    end

    def merge_train
      merge_request.merge_train
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
