# frozen_string_literal: true

class CredentialsInventoryMailer < ApplicationMailer
  helper EmailsHelper

  layout 'mailer'

  def personal_access_token_revoked_email(token:, revoked_by:)
    @revoked_by = revoked_by
    @token = token

    mail_with_locale(
      to: token.user.notification_email_or_default,
      subject: _('Your Personal Access Token was revoked')
    )
  end

  def ssh_key_deleted_email(params:, deleted_by:)
    @deleted_by = deleted_by
    @params = params

    mail_with_locale(
      to: params[:notification_email],
      subject: _('Your SSH key was deleted')
    )
  end
end
