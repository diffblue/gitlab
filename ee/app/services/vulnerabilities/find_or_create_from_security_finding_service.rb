# frozen_string_literal: true

module Vulnerabilities
  class FindOrCreateFromSecurityFindingService < ::BaseProjectService
    def initialize(project:, current_user:, params:, state:, present_on_default_branch: true)
      super(project: project, current_user: current_user, params: params)
      @state = state
      @present_on_default_branch = present_on_default_branch
    end

    def execute
      raise Gitlab::Access::AccessDeniedError unless can?(@current_user, :create_vulnerability, @project)

      with_vulnerability_finding do |vulnerability_finding|
        ServiceResponse.success(payload: { vulnerability: find_or_create_vulnerability(vulnerability_finding) })
      end
    end

    private

    def find_or_create_vulnerability(vulnerability_finding)
      if vulnerability_finding.vulnerability_id.nil?
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
    end

    def with_vulnerability_finding
      response = ::Vulnerabilities::Findings::FindOrCreateFromSecurityFindingService.new(
        project: project,
        current_user: current_user,
        params: params
      ).execute

      return response if response && response.error?

      yield response.payload[:vulnerability_finding]
    end
  end
end
