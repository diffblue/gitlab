# frozen_string_literal: true

module Vulnerabilities
  class FindingDismissService < BaseProjectService
    include Gitlab::Allowable

    def initialize(user, finding, comment = nil, dismissal_reason = nil)
      super(project: finding.project, current_user: user)
      @finding = finding
      @comment = comment
      @dismissal_reason = dismissal_reason
    end

    def execute
      return ServiceResponse.error(message: "Access denied", http_status: :forbidden) unless authorized?

      dismiss_finding
    end

    private

    def authorized?
      can?(@current_user, :admin_vulnerability, @project)
    end

    def dismiss_finding
      result = ::VulnerabilityFeedback::CreateService.new(
        @project,
        @current_user,
        feedback_params_for(@finding, @comment, @dismissal_reason)
      ).execute

      case result[:status]
      when :success
        ServiceResponse.success(payload: { finding: @finding })
      when :error
        all_errors = result[:message].full_messages.join(",")
        error_string = _("failed to dismiss finding: %{message}") % { message: all_errors }
        ServiceResponse.error(message: error_string, http_status: :unprocessable_entity)
      end
    end

    def feedback_params_for(finding, comment, dismissal_reason)
      {
        category: @finding.report_type,
        feedback_type: 'dismissal',
        project_fingerprint: @finding.project_fingerprint,
        comment: @comment,
        dismissal_reason: @dismissal_reason,
        pipeline: @project.latest_pipeline_with_security_reports(only_successful: true),
        finding_uuid: @finding.uuid_v5,
        dismiss_vulnerability: false
      }
    end
  end
end
