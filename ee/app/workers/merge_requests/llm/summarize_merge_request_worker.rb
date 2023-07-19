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

      SUMMARIZE_QUICK_ACTION = 'summarize_quick_action'
      PREPARE_DIFF_SUMMARY = 'prepare_diff_summary'

      def perform(user_id, params = {})
        params = params.with_indifferent_access

        @user = User.find_by_id(user_id)

        return unless user

        # We removed a param, and added the params, so need to handle the case
        # when type is not given
        if params['type'] == SUMMARIZE_QUICK_ACTION || params['type'].nil?
          merge_request = MergeRequest.find_by_id(params['merge_request_id'])
          return unless merge_request

          project = merge_request.project

          return unless user.can?(:create_note, project)

          summary = service(title: merge_request.title, diff: merge_request.merge_request_diff).execute
          return unless summary

          opts = {
            note: note_content(merge_request, summary),
            noteable_type: 'MergeRequest',
            noteable_id: merge_request.id
          }

          # Create the note, but attribute it to the LLM bot
          #
          Notes::CreateService.new(project, llm_service_bot, opts).execute
        elsif params['type'] == PREPARE_DIFF_SUMMARY
          diff = MergeRequestDiff.find_by_id(params['diff_id'])
          return unless diff

          summary = service(title: diff.merge_request.title, diff: diff).execute

          return unless summary

          provider = if ::Llm::MergeRequests::SummarizeDiffService.vertex_ai?(diff.merge_request.project)
                       :vertex_ai
                     else
                       :open_ai
                     end

          MergeRequest::DiffLlmSummary.create!(merge_request_diff: diff,
            content: summary,
            provider: MergeRequest::DiffLlmSummary.providers[provider])
        end
      end

      private

      attr_accessor :user

      def llm_service_bot
        @_llm_service_bot ||= User.llm_bot
      end

      # Until we decide the best way to represent generated content
      def note_content(merge_request, summary)
        rev = merge_request.diff_head_sha

        summary + "\n\n---\n_(AI-generated summary for revision #{rev})_"
      end

      def service(title:, diff:)
        @_service ||= ::Llm::MergeRequests::SummarizeDiffService.new(
          title: title,
          user: user,
          diff: diff
        )
      end
    end
  end
end

# Added for JiHu
MergeRequests::Llm::SummarizeMergeRequestWorker.prepend_mod
