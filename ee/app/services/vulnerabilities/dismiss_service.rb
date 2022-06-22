# frozen_string_literal: true

require_dependency 'vulnerabilities/base_service'

module Vulnerabilities
  class DismissService < BaseService
    FindingsDismissResult = Struct.new(:ok?, :finding, :message)

    def initialize(current_user, vulnerability, comment = nil, dismissal_reason = nil, dismiss_findings: true)
      super(current_user, vulnerability)
      @comment = comment
      @dismissal_reason = dismissal_reason
      @dismiss_findings = dismiss_findings
    end

    def execute
      raise Gitlab::Access::AccessDeniedError unless authorized?

      update_vulnerability_with(state: Vulnerability.states[:dismissed], dismissed_by: @user, dismissed_at: Time.current) do
        if dismiss_findings && Feature.disabled?(:deprecate_vulnerabilities_feedback, @vulnerability.project)
          result = dismiss_vulnerability_findings

          unless result.ok?
            handle_finding_dismissal_error(result.finding, result.message)
            raise ActiveRecord::Rollback
          end
        end
      end

      @vulnerability
    end

    private

    attr_reader :dismiss_findings

    def feedback_service_for(finding)
      VulnerabilityFeedback::CreateService.new(@project, @user, feedback_params_for(finding))
    end

    def feedback_params_for(finding)
      {
        category: finding.report_type,
        feedback_type: 'dismissal',
        project_fingerprint: finding.project_fingerprint,
        comment: @comment,
        dismissal_reason: @dismissal_reason,
        pipeline: @project.latest_ingested_security_pipeline,
        finding_uuid: finding.uuid_v5,
        dismiss_vulnerability: false
      }
    end

    def dismiss_vulnerability_findings
      unless Feature.enabled?(:deprecate_vulnerabilities_feedback, @project)
        @vulnerability.findings.each do |finding|
          result = feedback_service_for(finding).execute

          return FindingsDismissResult.new(false, finding, result[:message]) if result[:status] == :error
        end
      end

      FindingsDismissResult.new(true)
    end

    def handle_finding_dismissal_error(finding, message)
      @vulnerability.errors.add(
        :base,
        :finding_dismissal_error,
        message: _("failed to dismiss associated finding(id=%{finding_id}): %{message}") %
          {
            finding_id: finding.id,
            message: message
          })
    end
  end
end
