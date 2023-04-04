# frozen_string_literal: true

module Emails
  module ComplianceFrameworks
    def compliance_frameworks_csv_email(user:, group:, attachment:, filename:)
      @group = group
      attachments[filename] = { content: attachment, mime_type: 'text/csv' }

      email_with_layout(
        to: user.notification_email_for(group),
        subject: subject(s_("ComplianceFrameworks|Compliance Frameworks Export"))
      )
    end
  end
end
