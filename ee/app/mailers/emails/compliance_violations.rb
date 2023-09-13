# frozen_string_literal: true

module Emails
  module ComplianceViolations
    def compliance_violations_csv_email(user:, group:, attachment:, filename:)
      @group = group
      attachments[filename] = { content: attachment, mime_type: 'text/csv' }

      email_with_layout(
        to: user.notification_email_for(group),
        subject: subject(s_("ComplianceViolations|Compliance Violations Export"))
      )
    end
  end
end
