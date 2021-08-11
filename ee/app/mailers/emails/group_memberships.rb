# frozen_string_literal: true

module Emails
  module GroupMemberships
    def memberships_export_email(csv_data:, requested_by:, group:)
      @group = group

      filename = "#{group.full_path.parameterize}_group_memberships_#{Date.current.iso8601}.csv"
      attachments[filename] = { content: csv_data, mime_type: 'text/csv' }
      mail(to: requested_by.notification_email_for(group), subject: "Exported group membership list") do |format|
        format.html { render layout: 'mailer' }
        format.text { render layout: 'mailer' }
      end
    end
  end
end
