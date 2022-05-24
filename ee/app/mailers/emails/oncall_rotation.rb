# frozen_string_literal: true

module Emails
  module OncallRotation
    extend ActiveSupport::Concern

    def user_removed_from_rotation_email(user, rotation, recipients)
      @user = user
      @rotation = rotation
      @schedule = rotation.schedule
      @project = rotation.project

      email_with_layout(
        to: recipients.map(&:email),
        subject: subject('User removed from On-call rotation'))
    end
  end
end
