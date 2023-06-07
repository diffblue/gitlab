# frozen_string_literal: true

module Security
  module ScanResultPolicies
    class GeneratePolicyViolationCommentService
      attr_reader :merge_request, :project, :violated_policy

      def initialize(merge_request, violated_policy)
        @merge_request = merge_request
        @project = merge_request.project
        @violated_policy = violated_policy
      end

      def execute
        note = if bot_comment
                 update_comment
               elsif violated_policy
                 create_comment
               end

        return ServiceResponse.success if note.nil? || note.persisted?

        ServiceResponse.error(message: note.errors.full_messages)
      end

      private

      def update_comment
        body = violated_policy ? violations_note_body : fixed_note_body
        Notes::UpdateService.new(project, bot_user, note_params(body)).execute(bot_comment)
      end

      def create_comment
        Notes::CreateService.new(project, bot_user, note_params(violations_note_body)).execute
      end

      def bot_comment
        @bot_comment ||= merge_request.notes.authored_by(bot_user).first
      end

      def bot_user
        @bot_user ||= User.security_bot
      end

      def note_params(body)
        {
          note: body,
          noteable: merge_request
        }
      end

      def fixed_note_body
        'Security policy violations have been resolved.'
      end

      def violations_note_body
        message = <<~TEXT.squish
          Security and compliance scanners enforced by your organization have completed and identified that approvals
          are required due to one or more policy violations.
          Review the policy's rules in the MR widget and assign reviewers to proceed.
        TEXT
        <<~MARKDOWN
          | :warning: **Policy violation(s) detected**|
          | ----------------------------------------- |
          | #{message}                                |

          #{format('Learn more about [Security and Compliance policies](%{url}).',
            url: Rails.application.routes.url_helpers.help_page_url('user/application_security/policies'))}
        MARKDOWN
      end
    end
  end
end
