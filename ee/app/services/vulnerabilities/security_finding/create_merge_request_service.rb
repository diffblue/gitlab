# frozen_string_literal: true

module Vulnerabilities
  module SecurityFinding
    class CreateMergeRequestService < ::BaseProjectService
      attr_reader :error_message

      def execute
        raise Gitlab::Access::AccessDeniedError unless can?(@current_user, :read_security_resource, @project)

        merge_request = nil
        @error_message = nil

        ApplicationRecord.transaction do
          merge_request = create_merge_request
          vulnerability = find_or_create_vulnerability
          create_vulnerability_merge_request_link(vulnerability, merge_request)
        end

        return error_response if @error_message

        success_response(merge_request)
      end

      def create_merge_request
        merge_request_response = MergeRequests::CreateFromVulnerabilityDataService.new(@project,
                                                                                       @current_user,
                                                                                       vulnerability_data).execute

        if merge_request_response[:status] != :success
          @error_message = merge_request_response[:message]
          raise ActiveRecord::Rollback
        end

        merge_request_response[:merge_request]
      end

      def vulnerability_data
        params[:vulnerability_data]
      end

      def find_or_create_vulnerability
        finding_params = { security_finding_uuid: params[:security_finding_uuid] }
        response = Vulnerabilities::FindOrCreateFromSecurityFindingService.new(project: @project,
                                                                               current_user: @current_user,
                                                                               params: finding_params,
                                                                               state: 'confirmed').execute

        if response.error?
          @error_message = response[:message]
          raise ActiveRecord::Rollback
        end

        response.payload[:vulnerability]
      end

      def create_vulnerability_merge_request_link(vulnerability, merge_request)
        params = { vulnerability: vulnerability, merge_request: merge_request }
        merge_request_link_response = VulnerabilityMergeRequestLinks::CreateService.new(project: @project,
                                                                                        current_user: @current_user,
                                                                                        params: params).execute

        if merge_request_link_response.error?
          @error_message = merge_request_link_response[:message]
          raise ActiveRecord::Rollback
        end

        merge_request_link_response.payload[:merge_request_link]
      end

      def error_response
        ServiceResponse.error(message: @error_message)
      end

      def success_response(merge_request)
        ServiceResponse.success(payload: { merge_request: merge_request })
      end
    end
  end
end
