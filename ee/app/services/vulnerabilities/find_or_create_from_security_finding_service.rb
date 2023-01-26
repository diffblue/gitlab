# frozen_string_literal: true

module Vulnerabilities
  class FindOrCreateFromSecurityFindingService < ::BaseProjectService
    def initialize(
      project:, current_user:, params:, state:, present_on_default_branch: true,
      skip_permission_check: false)
      super(project: project, current_user: current_user, params: params)
      @state = state
      @present_on_default_branch = present_on_default_branch
      @skip_permission_check = skip_permission_check
    end

    def execute
      if !@skip_permission_check && !can?(@current_user, :create_vulnerability, @project)
        raise Gitlab::Access::AccessDeniedError
      end

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
          present_on_default_branch: @present_on_default_branch,
          comment: params[:comment],
          dismissal_reason: params[:dismissal_reason],
          skip_permission_check: @skip_permission_check
        ).execute
      else
        vulnerability = Vulnerability.find(vulnerability_finding.vulnerability_id)
        update_state_for(vulnerability) if vulnerability.state != @state.to_s
        vulnerability
      end
    end

    def update_state_for(vulnerability)
      vulnerability.transaction do
        state_transition_params = {
          vulnerability: vulnerability,
          from_state: vulnerability.state,
          to_state: @state,
          author: @current_user
        }

        state_transition_params[:comment] = params[:comment] if params[:comment]
        state_transition_params[:dismissal_reason] = params[:dismissal_reason] if params[:dismissal_reason]

        Vulnerabilities::StateTransition.create!(state_transition_params)

        vulnerability.update!(state: @state)
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
