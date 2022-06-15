# frozen_string_literal: true

module AutoMerge
  class AddToMergeTrainWhenPipelineSucceedsService < AutoMerge::BaseService
    def execute(merge_request)
      super do
        SystemNoteService.add_to_merge_train_when_pipeline_succeeds(merge_request, project, current_user, merge_request.actual_head_pipeline.sha)
      end
    end

    def process(merge_request)
      return unless merge_request.actual_head_pipeline_success?

      merge_train_service = AutoMerge::MergeTrainService.new(project, merge_request.merge_user)

      return abort(merge_request, 'This merge request cannot be added to the merge train') unless merge_train_service.available_for?(merge_request)

      merge_train_service.execute(merge_request)
    end

    def cancel(merge_request)
      super do
        SystemNoteService.cancel_add_to_merge_train_when_pipeline_succeeds(merge_request, project, current_user)
      end
    end

    def abort(merge_request, reason)
      super do
        SystemNoteService.abort_add_to_merge_train_when_pipeline_succeeds(merge_request, project, current_user, reason)
      end
    end

    def available_for?(merge_request)
      super do
        merge_request.project.merge_trains_enabled? &&
          merge_request.actual_head_pipeline&.active?
      end
    end
  end
end
