# frozen_string_literal: true

module Vulnerabilities
  class CreateService
    include Gitlab::Allowable
    include Gitlab::Utils::StrongMemoize

    def initialize(
      project,
      author,
      finding_id:,
      state: nil,
      present_on_default_branch: true,
      comment: nil,
      dismissal_reason: nil
    )
      @project = project
      @author = author
      @finding_id = finding_id
      @state = state
      @present_on_default_branch = present_on_default_branch
      @comment = comment
      @dismissal_reason = dismissal_reason
    end

    def execute
      raise Gitlab::Access::AccessDeniedError unless can?(@author, :create_vulnerability, @project)

      vulnerability = Vulnerability.new

      Vulnerabilities::Finding.transaction do
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
      from_state = finding.state
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
        dismissed_at: determine_dismissed_at,
        dismissed_by_id: determine_dismissed_by_id,
        present_on_default_branch: @present_on_default_branch
      )

      vulnerability.save && vulnerability.findings << finding
      create_state_transition_if_needed(vulnerability, from_state) if @state
    end

    def determine_dismissed_at
      if Feature.enabled?(:deprecate_vulnerabilities_feedback, @project)
        @state == :dismissed ? Time.current : nil
      else
        existing_dismissal_feedback&.created_at
      end
    end

    def determine_dismissed_by_id
      if Feature.enabled?(:deprecate_vulnerabilities_feedback, @project)
        @state == :dismissed ? @author.id : nil
      else
        existing_dismissal_feedback&.author_id
      end
    end

    def create_state_transition_if_needed(vulnerability, from_state)
      return if from_state == @state

      state_transition_params = {
        vulnerability: vulnerability,
        from_state: from_state,
        to_state: @state
      }

      state_transition_params[:comment] = @comment if @comment
      state_transition_params[:dismissal_reason] = @dismissal_reason if @dismissal_reason

      Vulnerabilities::StateTransition.create!(state_transition_params)
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
