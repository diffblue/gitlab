# frozen_string_literal: true

module MergeRequests
  module Llm
    class SummarizeMergeRequestWorker
      include ApplicationWorker

      data_consistency :always
      feature_category :code_review_workflow
      urgency :low
      deduplicate :until_executed

      worker_has_external_dependencies!
      idempotent!

      def perform(merge_request_id, user_id, rev = nil)
        @merge_request = MergeRequest.find_by_id(merge_request_id)
        return unless @merge_request

        @project = @merge_request.project

        @user = User.find_by_id(user_id)
        return unless @user && @user.can?(:create_note, @project)

        # If rev is not provided, use the SHA of the current head commit.
        #
        # Note that MergeRequests::Llm::SummarizeMergeRequestService does not
        #   currently support summarizing anything except the most recent diff,
        #   and providing it when calling this worker aids in job deduplication.
        #   We will display the rev at the end of the note in order to identify
        #   which version what summarized.
        #
        rev ||= @merge_request.diff_head_sha

        summary = service.execute
        return unless summary

        opts = {
          note: note_content(summary, rev),
          noteable_type: 'MergeRequest',
          noteable_id: @merge_request.id
        }

        Notes::CreateService.new(@project, @user, opts).execute
      end

      private

      # Until we decide the best way to represent generated content
      def note_content(summary, rev)
        summary + "\n\n(Summary note created by LLM 🤖 for revision #{rev})"
      end

      def service
        @_service ||= MergeRequests::Llm::SummarizeMergeRequestService.new(
          merge_request: @merge_request,
          user: @user
        )
      end
    end
  end
end
