# frozen_string_literal: true

module Emails
  module Okr
    def okr_checkin_reminder_notification(user:, work_item:, project:)
      return unless user
      return unless work_item.assignee?(user)

      @user = user
      @project = project
      @work_item = work_item
      @author = work_item.author

      ::Gitlab::I18n.with_locale(@user.preferred_language) do
        mail(to: @user.notification_email_for(@project.group),
          subject: subject("#{@work_item.title} (##{@work_item.iid})"))
      end
    end
  end
end
