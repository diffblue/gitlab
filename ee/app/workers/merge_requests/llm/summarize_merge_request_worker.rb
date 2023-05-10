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
        # Note that Llm::MergeRequests::SummarizeDiffService does not
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

        # Create the note, but attribute it to the LLM bot
        #
        Notes::CreateService.new(@project, llm_service_bot, opts).execute
      end

      private

      def llm_service_bot
        @_llm_service_bot ||= User.llm_bot
      end

      # Until we decide the best way to represent generated content
      def note_content(summary, rev)
        summary + "\n\n---\n_(AI-generated summary for revision #{rev})_"
      end

      def service
        @_service ||= ::Llm::MergeRequests::SummarizeDiffService.new(
          merge_request: @merge_request,
          user: @user
        )
      end
    end
  end
end
