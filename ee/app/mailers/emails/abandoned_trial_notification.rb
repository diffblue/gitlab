# frozen_string_literal: true

module Emails
  module AbandonedTrialNotification
    def abandoned_trial_notification(user_id)
      user = User.find_by_id(user_id)
      return unless user

      email = user.notification_email_or_default
      email_with_layout to: email, subject: 'Help us improve GitLab'
    end
  end
end
