# frozen_string_literal: true

module EE
  module Emails
    module Issues
      def removed_iteration_issue_email(recipient_id, issue_id, updated_by_user_id, reason = nil)
        setup_issue_mail(issue_id, recipient_id)

        mail_answer_thread(@issue, issue_thread_options(updated_by_user_id, reason))
      end

      def changed_iteration_issue_email(recipient_id, issue_id, iteration, updated_by_user_id, reason = nil)
        setup_issue_mail(issue_id, recipient_id)

        @iteration = iteration
        @iteration_url = iteration_url(@iteration)
        mail_answer_thread(@issue, issue_thread_options(updated_by_user_id, reason).merge({
          template_name: 'changed_iteration_email'
        }))
      end
    end
  end
end
