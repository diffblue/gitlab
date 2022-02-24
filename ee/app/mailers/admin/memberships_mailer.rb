# frozen_string_literal: true

class Admin::MembershipsMailer < ApplicationMailer
  helper EmailsHelper

  layout 'mailer'

  def instance_memberships_export(requested_by:)
    filename = "gitlab_memberships_#{Date.current.iso8601}.csv"
    csv_data = UserPermissions::ExportService.new.execute.payload[:csv_data]
    attachments[filename] = { content: csv_data, mime_type: 'text/csv' }

    mail(
      to: requested_by.notification_email_or_default,
      subject: _('GitLab Memberships CSV Export')
    )
  end
end
