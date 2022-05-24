# frozen_string_literal: true

module Emails
  module GroupMemberships
    def memberships_export_email(csv_data:, requested_by:, group:)
      @group = group

      filename = "#{group.full_path.parameterize}_group_memberships_#{Date.current.iso8601}.csv"
      attachments[filename] = { content: csv_data, mime_type: 'text/csv' }
      email_with_layout(
        to: requested_by.notification_email_for(group),
        subject: "Exported group membership list")
    end
  end
end
