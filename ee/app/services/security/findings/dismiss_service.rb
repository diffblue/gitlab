# frozen_string_literal: true

module Security
  module Findings
    class DismissService < BaseProjectService
      include Gitlab::Allowable

      def initialize(user:, security_finding:, comment: nil, dismissal_reason: nil)
        super(project: security_finding.project, current_user: user)
        @security_finding = security_finding
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
        result = if Feature.enabled?(:deprecate_vulnerabilities_feedback, @project)
                   create_and_dismiss_vulnerability
                 else
                   ::VulnerabilityFeedback::CreateService.new(
                     @project,
                     @current_user,
                     feedback_params
                   ).execute
                 end

        if result[:status] == :success
          ServiceResponse.success(payload: { security_finding: @security_finding })
        else
          all_errors = result[:message].full_messages.join(",")
          error_string = format(_("failed to dismiss security finding: %{message}"), message: all_errors)
          ServiceResponse.error(message: error_string, http_status: :unprocessable_entity)
        end
      end

      def create_and_dismiss_vulnerability
        security_finding_params = {
          security_finding_uuid: @security_finding.uuid,
          comment: @comment,
          dismissal_reason: @dismissal_reason
        }

        ::Vulnerabilities::FindOrCreateFromSecurityFindingService.new(project: @project,
                                                                      current_user: @current_user,
                                                                      params: security_finding_params,
                                                                      state: :dismissed,
                                                                      present_on_default_branch: false).execute
      end

      def feedback_params
        {
          category: @security_finding.scan_type,
          feedback_type: 'dismissal',
          project_fingerprint: @security_finding.project_fingerprint,
          comment: @comment,
          dismissal_reason: @dismissal_reason,
          pipeline: @security_finding.pipeline,
          finding_uuid: @security_finding.uuid,
          dismiss_vulnerability: false
        }
      end
    end
  end
end
