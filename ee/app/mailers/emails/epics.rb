# frozen_string_literal: true

module Emails
  module Epics
    def new_epic_email(recipient_id, epic_id, reason = nil)
      @epic = Epic.find_by_id(epic_id)
      return unless @epic

      setup_epic_mail(recipient_id)

      mail_new_thread(@epic, epic_thread_options(@epic.author_id, reason))
    end

    def epic_status_changed_email(recipient_id, epic_id, status, updated_by_user_id, reason = nil)
      @epic = Epic.find_by_id(epic_id)
      return unless @epic

      setup_epic_mail(recipient_id)

      @status = status
      @updated_by = User.find(updated_by_user_id)

      mail_answer_thread(@epic, epic_thread_options(updated_by_user_id, reason))
    end

    private

    def setup_epic_mail(recipient_id)
      @group = @epic.group
      @target_url = group_epic_url(@epic.group, @epic)
      @recipient = User.find(recipient_id)

      add_group_headers

      @sent_notification = SentNotification.record(@epic, recipient_id, reply_key)
    end

    def epic_thread_options(sender_id, reason)
      {
        from: sender(sender_id),
        to: @recipient.notification_email_for(@epic.group),
        subject: subject("#{@epic.title} (#{@epic.to_reference})"),
        'X-GitLab-NotificationReason' => reason
      }
    end
  end
end
