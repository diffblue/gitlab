# frozen_string_literal: true

class LicenseMailerPreview < ActionMailer::Preview
  def approaching_active_user_count_limit
    ::LicenseMailer.approaching_active_user_count_limit(%w[admin@example.com])
  end
end
