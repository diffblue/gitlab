# frozen_string_literal: true

module Security
  module ScanResultPolicies
    class GeneratePolicyViolationCommentService
      include ::Gitlab::ExclusiveLeaseHelpers

      LOCK_SLEEP_SEC = 0.5.seconds

      attr_reader :merge_request, :project, :report_type, :violated_policy, :requires_approval

      def initialize(merge_request, params = {})
        @merge_request = merge_request
        @project = merge_request.project
        @report_type = params['report_type']
        @violated_policy = params['violated_policy']
        @requires_approval = params['requires_approval']
      end

      def execute
        in_lock(exclusive_lock_key, sleep_sec: LOCK_SLEEP_SEC) do
          break ServiceResponse.success if comment.body.blank?

          note = if existing_comment
                   Notes::UpdateService.new(project, bot_user, note_params(comment.body)).execute(existing_comment)
                 else
                   Notes::CreateService.new(project, bot_user, note_params(comment.body)).execute
                 end

          if note.nil? || note.persisted?
            ServiceResponse.success
          else
            ServiceResponse.error(message: note.errors.full_messages)
          end
        end
      rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
        ServiceResponse.error(message: ['Failed to obtain an exclusive lock'])
      end

      private

      def exclusive_lock_key
        "#{self.class.name.underscore}::merge_request_id:#{merge_request.id}"
      end

      def comment
        @comment ||= PolicyViolationComment.new(existing_comment).tap do |violation_comment|
          if violated_policy
            violation_comment.add_report_type(report_type, requires_approval)
          else
            violation_comment.remove_report_type(report_type)
          end
        end
      end

      def existing_comment
        @existing_comment ||= merge_request.notes
                                           .authored_by(bot_user)
                                           .note_starting_with(PolicyViolationComment::MESSAGE_HEADER).first
      end

      def bot_user
        @bot_user ||= Users::Internal.security_bot
      end

      def note_params(body)
        {
          note: body,
          noteable: merge_request
        }
      end
    end
  end
end
