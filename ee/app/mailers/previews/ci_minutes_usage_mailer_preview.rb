# frozen_string_literal: true

class CiMinutesUsageMailerPreview < ActionMailer::Preview
  def out_of_minutes
    ::CiMinutesUsageMailer.notify(Group.last, %w[bob@example.com])
  end

  def limit_warning
    ::CiMinutesUsageMailer.notify_limit(Group.last, %w[bob@example.com], 30)
  end
end
