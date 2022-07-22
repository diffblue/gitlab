# frozen_string_literal: true

module Vulnerabilities
  class CreateService
    include Gitlab::Allowable
    include Gitlab::Utils::StrongMemoize

    def initialize(project, author, finding_id:, state: nil, present_on_default_branch: true)
      @project = project
      @author = author
      @finding_id = finding_id
      @state = state
      @present_on_default_branch = present_on_default_branch
    end

    def execute
      raise Gitlab::Access::AccessDeniedError unless can?(@author, :create_vulnerability, @project)

      vulnerability = Vulnerability.new

      Vulnerabilities::Finding.transaction(requires_new: true) do # rubocop:disable Performance/ActiveRecordSubtransactions
        save_vulnerability(vulnerability, finding)
      rescue ActiveRecord::RecordNotFound
        vulnerability.errors.add(:base, _('finding is not found or is already attached to a vulnerability'))
        raise ActiveRecord::Rollback
      end

      if vulnerability.persisted?
        Statistics::UpdateService.update_for(vulnerability)
      end

      vulnerability
    end

    private

    def save_vulnerability(vulnerability, finding)
      vulnerability.assign_attributes(
        author: @author,
        project: @project,
        title: finding.name.truncate(::Issuable::TITLE_LENGTH_MAX),
        state: @state || finding.state,
        severity: finding.severity,
        severity_overridden: false,
        confidence: finding.confidence,
        confidence_overridden: false,
        report_type: finding.report_type,
        dismissed_at: existing_dismissal_feedback&.created_at,
        dismissed_by_id: existing_dismissal_feedback&.author_id,
        present_on_default_branch: @present_on_default_branch
      )

      vulnerability.save && vulnerability.findings << finding
    end

    def existing_dismissal_feedback
      strong_memoize(:existing_dismissal_feedback) { finding.dismissal_feedback }
    end

    def finding
      # we're using `lock` instead of `with_lock` to avoid extra call to `find` under the hood
      @finding ||= @project.vulnerability_findings.lock_for_confirmation!(@finding_id)
    end
  end
end
