# frozen_string_literal: true

module EE
  module NewIssueWorker
    extend ::Gitlab::Utils::Override

    private

    def log_audit_event
      audit_context = {
        name: "#{issuable.issue_type}_created_by_project_bot",
        author: user,
        scope: issuable.respond_to?(:group) ? issuable.group : issuable.project,
        target: issuable,
        message: "Created #{issuable.issue_type.humanize(capitalize: false)} #{issuable.title}",
        target_details: { iid: issuable.iid, id: issuable.id }
      }

      ::Gitlab::Audit::Auditor.audit(audit_context)
    end
  end
end
