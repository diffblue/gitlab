# frozen_string_literal: true

class LicenseMailer < ApplicationMailer
  helper EmailsHelper

  layout 'mailer'

  def approaching_active_user_count_limit(recipients)
    @license = License.current

    return unless @license

    mail_with_locale(
      bcc: recipients,
      subject: "Your subscription is nearing its user limit"
    )
  end
end
