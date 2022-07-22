# frozen_string_literal: true

module Vulnerabilities
  class CreateFromSecurityFindingService < ::BaseProjectService
    def initialize(project:, current_user:, params:, state:, present_on_default_branch:)
      super(project: project, current_user: current_user, params: params)
      @state = state
      @present_on_default_branch = present_on_default_branch
    end

    def execute
      raise Gitlab::Access::AccessDeniedError unless can?(@current_user, :create_vulnerability, @project)

      response = create_vulnerability_finding unless vulnerability_finding

      return response if response && response.error?

      vulnerability = if vulnerability_finding.vulnerability_id.nil?
                        Vulnerabilities::CreateService.new(
                          @project,
                          @current_user,
                          finding_id: vulnerability_finding.id,
                          state: @state,
                          present_on_default_branch: @present_on_default_branch
                        ).execute
                      else
                        Vulnerability.find(vulnerability_finding.vulnerability_id)
                      end

      ServiceResponse.success(payload: { vulnerability: vulnerability })
    end

    def vulnerability_finding
      @vulnerability_finding ||= Vulnerabilities::Finding.by_uuid(params[:security_finding_uuid]).last
    end

    private

    def create_vulnerability_finding
      response = ::Vulnerabilities::Findings::CreateFromSecurityFindingService.new(
        project: project,
        current_user: current_user,
        params: params
      ).execute
      @vulnerability_finding = response.payload[:vulnerability_finding]

      response
    end
  end
end
