# frozen_string_literal: true

module AutoMerge
  class MergeWhenChecksPassService < AutoMerge::MergeWhenPipelineSucceedsService
    extend Gitlab::Utils::Override

    override :skip_draft_check
    def skip_draft_check(merge_request)
      Feature.enabled?(:additional_merge_when_checks_ready, merge_request.project)
    end

    private

    def add_system_note(merge_request)
      return unless merge_request.saved_change_to_auto_merge_enabled?

      SystemNoteService.merge_when_checks_pass(
        merge_request,
        project,
        current_user,
        merge_request.actual_head_pipeline.sha
      )
    end

    def check_availability(merge_request)
      return false if Feature.disabled?(:merge_when_checks_pass, merge_request.project)
      return false unless merge_request.approval_feature_available?

      super ||
        !merge_request.approved? ||
        (merge_request.draft? && Feature.enabled?(:additional_merge_when_checks_ready, merge_request.project))
    end
  end
end
