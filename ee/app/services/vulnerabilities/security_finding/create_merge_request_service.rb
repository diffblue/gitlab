# frozen_string_literal: true

module Vulnerabilities
  module SecurityFinding
    class CreateMergeRequestService < ::BaseProjectService
      def execute
        enforce_authorization!

        @error_message = nil

        merge_request = ApplicationRecord.transaction do
          create_merge_request.tap do |merge_request|
            create_vulnerability_merge_request_link(merge_request, find_or_create_vulnerability)
          end
        end

        merge_request.present? ? success_response(merge_request) : error_response(@error_message)
      end

      private

      def enforce_authorization!
        return if can?(current_user, :read_security_resource, project)

        raise Gitlab::Access::AccessDeniedError
      end

      def execute_service!(service)
        response = service.execute
        return response if response[:status] == :success

        @error_message = response[:message]
        raise ActiveRecord::Rollback
      end

      def create_merge_request
        execute_service!(
          MergeRequests::CreateFromVulnerabilityDataService
            .new(project, current_user, vulnerability_data)
        )[:merge_request]
      end

      def find_or_create_vulnerability
        execute_service!(
          Vulnerabilities::FindOrCreateFromSecurityFindingService
            .new(project: project, current_user: current_user, params: {
              security_finding_uuid: params[:security_finding].uuid
            }, state: 'confirmed')
        ).payload[:vulnerability]
      end

      def create_vulnerability_merge_request_link(merge_request, vulnerability)
        execute_service!(
          VulnerabilityMergeRequestLinks::CreateService
            .new(project: project, current_user: current_user, params: {
              vulnerability: vulnerability,
              merge_request: merge_request
            })
        ).payload[:merge_request_link]
      end

      def vulnerability_data
        security_finding = params[:security_finding]
        vulnerability_finding = find_or_create_vulnerability_finding_for(security_finding)
        vulnerability_finding.metadata.with_indifferent_access.tap do |metadata|
          metadata[:category] = security_finding.scan.scan_type if metadata[:category].blank?
        end
      end

      def find_or_create_vulnerability_finding_for(security_finding)
        vulnerability_finding = security_finding.vulnerability_finding
        return vulnerability_finding if vulnerability_finding.present?

        execute_service!(
          ::Vulnerabilities::Findings::FindOrCreateFromSecurityFindingService.new(
            project: project,
            current_user: current_user,
            params: {
              security_finding_uuid: security_finding.uuid
            }
          )
        ).payload[:vulnerability_finding]
      end

      def error_response(message)
        ServiceResponse.error(message: message)
      end

      def success_response(merge_request)
        ServiceResponse.success(payload: { merge_request: merge_request })
      end
    end
  end
end
