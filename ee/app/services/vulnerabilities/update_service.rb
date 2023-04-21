# frozen_string_literal: true

module Vulnerabilities
  class UpdateService
    include Gitlab::Allowable

    attr_reader :project, :author, :finding, :resolved_on_default_branch

    delegate :vulnerability, to: :finding

    def initialize(project, author, finding:, resolved_on_default_branch: nil)
      @project = project
      @author = author
      @finding = finding
      @resolved_on_default_branch = resolved_on_default_branch
    end

    def execute
      raise Gitlab::Access::AccessDeniedError unless can?(author, :admin_vulnerability, project)

      vulnerability.update!(vulnerability_params)
      Statistics::UpdateService.update_for(vulnerability)

      vulnerability
    end

    private

    def vulnerability_params
      {
        title: finding.name.truncate(::Issuable::TITLE_LENGTH_MAX),
        severity: vulnerability.severity_overridden? ? vulnerability.severity : finding.severity,
        confidence: vulnerability.confidence_overridden? ? vulnerability.confidence : finding.confidence,
        resolved_on_default_branch: resolved_on_default_branch.nil? ? vulnerability.resolved_on_default_branch : resolved_on_default_branch
      }
    end
  end
end
