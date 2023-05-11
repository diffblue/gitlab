# frozen_string_literal: true

module Audit
  class MergeRequestDestroyAuditor
    attr_reader :merge_request, :current_user

    def initialize(merge_request, current_user)
      @merge_request = merge_request
      @current_user = current_user
    end

    def execute
      return unless current_user

      event_name = merge_request.merged? ? 'merged_merge_request_deleted' : "delete_merge_request"

      audit_context = {
        name: event_name,
        stream_only: true,
        author: current_user,
        target: merge_request,
        scope: merge_request.resource_parent,
        message: audit_event_message,
        target_details: {
          title: merge_request.title,
          iid: merge_request.iid,
          id: merge_request.id,
          type: merge_request.class.name
        }
      }

      ::Gitlab::Audit::Auditor.audit(audit_context)
    end

    private

    def audit_event_message
      if merge_request.merged?
        labels = merge_request.labels.pluck_titles.to_sentence
        approvers = merge_request.approved_by_user_ids.to_sentence
        merged_by_id = merge_request.metrics&.merged_by_id
        committer_ids = merge_request.commits.committer_user_ids.to_sentence

        message = "Removed MergeRequest(#{merge_request.title} with IID: #{merge_request.iid} " \
                  "and ID: #{merge_request.id}), labels: #{labels}, approved_by_user_ids: #{approvers}, " \
                  "committer_user_ids: #{committer_ids}"

        message += ", merged_by_user_id: #{merged_by_id}" if merged_by_id.present?

        message
      else
        "Removed MergeRequest(#{merge_request.title} with IID: #{merge_request.iid} and ID: #{merge_request.id})"
      end
    end
  end
end
