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

      update_vulnerability_with(state: :dismissed, dismissed_by: @user, dismissed_at: Time.current) do
        begin
          Vulnerabilities::StateTransition.create!(
            vulnerability: @vulnerability,
            from_state: @vulnerability.state,
            to_state: :dismissed,
            comment: @comment,
            dismissal_reason: @dismissal_reason,
            author: @user
          )
        rescue ActiveRecord::RecordInvalid => invalid
          errors = invalid.record.errors
          messages = errors.full_messages.join
          raise Gitlab::Graphql::Errors::ArgumentError, messages if errors[:to_state].present?
        end

        if dismiss_findings
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
        dismiss_vulnerability: false,
        migrated_to_state_transition: true
      }
    end

    def dismiss_vulnerability_findings
      @vulnerability.findings.each do |finding|
        result = feedback_service_for(finding).execute

        return FindingsDismissResult.new(false, finding, result[:message]) if result[:status] == :error
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
