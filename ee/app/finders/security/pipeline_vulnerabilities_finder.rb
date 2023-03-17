# frozen_string_literal: true

# Security::PipelineVulnerabilitiesFinder
#
# Used to retrieve security vulnerabilities from an associated Pipeline,
# This involves normalizing Report::Occurrence POROs to Vulnerabilities::Finding
#
# Arguments:
#   pipeline - object to filter vulnerabilities
#   params:
#     report_type: Array<String>

# DEPRECATED: This finder class is deprecated and will be removed
# by https://gitlab.com/gitlab-org/gitlab/-/issues/334488.
# Please inform us by adding a comment to aforementioned issue,
# if you need to add an extra feature to this class.
module Security
  class PipelineVulnerabilitiesFinder
    include Gitlab::Utils::StrongMemoize
    ParseError = Class.new(Gitlab::Ci::Parsers::ParserError)

    attr_accessor :params
    attr_reader :pipeline

    def initialize(pipeline:, params: {})
      @pipeline = pipeline
      @params = params
    end

    def execute
      findings = requested_reports.each_with_object([]) do |report, findings|
        raise ParseError, 'JSON parsing failed' if report.errored?

        valid_findings = report.findings.select(&:valid?)

        normalized_findings = normalize_report_findings(
          valid_findings,
          existing_vulnerabilities_for(valid_findings))

        filtered_findings = filter(normalized_findings)

        findings.concat(filtered_findings)
      end

      Gitlab::Ci::Reports::Security::AggregatedReport.new(requested_reports, sort_findings(findings))
    end

    private

    def sort_findings(findings)
      # This sort is stable (see https://en.wikipedia.org/wiki/Sorting_algorithm#Stability) contrary to the bare
      # Ruby sort_by method. Using just sort_by leads to instability across different platforms (e.g., x86_64-linux and
      # x86_64-darwin18) which in turn leads to different sorting results for the equal elements across these platforms.
      # This is important because it breaks test suite results consistency between local and CI
      # environment.
      # This is easier to address from within the class rather than from tests because this leads to bad class design
      # and exposing too much of its implementation details to the test suite.
      Gitlab::Utils.stable_sort_by(findings) { |x| [-x.severity_value] }
    end

    def requested_reports
      @requested_reports ||= pipeline&.security_reports(report_types: report_types)&.reports&.values || []
    end

    def existing_vulnerabilities_for(findings)
      findings.map(&:uuid)
              .each_slice(50)
              .flat_map { |uuids| Vulnerability.with_findings_by_uuid(uuids) }
              .index_by(&:finding_uuid)
    end

    # This finder is used for fetching vulnerabilities for any pipeline, if we used it to fetch
    # vulnerabilities for a non-default-branch, the findings will be unpersisted, so we
    # coerce the POROs into unpersisted AR records to give them a common object.
    # See https://gitlab.com/gitlab-org/gitlab/issues/33588#note_291849433 for more context
    # on why this happens.
    def normalize_report_findings(report_findings, vulnerabilities)
      report_findings.map do |report_finding|
        finding_hash = report_finding.to_hash
          .except(:compare_key, :identifiers, :location, :scanner, :links, :signatures, :flags, :evidence)

        finding = Vulnerabilities::Finding.new(finding_hash)
        # assigning Vulnerabilities to Findings to enable the computed state
        finding.location_fingerprint = report_finding.location.fingerprint
        finding.vulnerability = vulnerabilities[finding.uuid]
        finding.project = pipeline.project
        finding.sha = pipeline.sha
        finding.found_by_pipeline = report_finding.found_by_pipeline
        finding.scanner = scanner_for_report_finding(report_finding)
        finding.finding_links = report_finding.links.map do |link|
          Vulnerabilities::FindingLink.new(link.to_hash)
        end
        finding.identifiers = report_finding.identifiers.map do |identifier|
          Vulnerabilities::Identifier.new(identifier.to_hash)
        end
        finding.signatures = report_finding.signatures.map do |signature|
          Vulnerabilities::FindingSignature.new(signature.to_hash)
        end
        finding.finding_evidence = Vulnerabilities::Finding::Evidence.new(data: report_finding.evidence.data) if report_finding.evidence
        finding.details = report_finding.details

        if calculate_false_positive?
          finding.vulnerability_flags = report_finding.flags.map do |flag|
            Vulnerabilities::Flag.new(flag)
          end
        end

        finding
      end
    end

    # This will look for existing scanners, and if none found, build a non-persistent scanner object
    def scanner_for_report_finding(report_finding)
      @existing_scanners ||= pipeline.project.vulnerability_scanners.index_by(&:external_id)
      scanner = @existing_scanners[report_finding.scanner&.external_id] ||
        Vulnerabilities::Scanner.new(report_finding.scanner&.to_hash&.merge(project: pipeline.project))
      scanner.scan_type = report_finding.report_type
      scanner
    end

    def calculate_false_positive?
      project = pipeline.project
      project.licensed_feature_available?(:sast_fp_reduction)
    end

    def filter(findings)
      findings.select do |finding|
        next unless in_selected_state?(finding)
        next if !include_dismissed? && dismissal_feedback?(finding)
        next unless confidence_levels.include?(finding.confidence)
        next unless severity_levels.include?(finding.severity)
        next if scanners.present? && !scanners.include?(finding.scanner.external_id)

        finding
      end
    end

    def in_selected_state?(finding)
      params[:state].blank? || states.include?(computed_finding_state(finding))
    end

    # Here we are checking the state of the `vulnerability` and preloaded `feedback` records
    # instead of checking the `finding.state` as the `state` method of the `finding` fires
    # an additional database query to load the `feedback` record for each `finding`.
    def computed_finding_state(finding)
      if Feature.enabled?(:deprecate_vulnerabilities_feedback, pipeline.project)
        finding.state
      else
        finding.vulnerability&.state ||
          (dismissal_feedback?(finding) ? 'dismissed' : 'detected')
      end
    end

    def include_dismissed?
      skip_scope_parameter? || params[:scope] == 'all'
    end

    # If the client explicitly asks for the dismissed findings, we shouldn't
    # filter by the `scope` parameter as it's `skip_dismissed` by default.
    def skip_scope_parameter?
      params[:state].present? && states.include?('dismissed')
    end

    def dismissal_feedback?(finding)
      return true if Feature.enabled?(:deprecate_vulnerabilities_feedback, pipeline.project) && finding.vulnerability&.dismissed?

      if pipeline.project.licensed_feature_available?(:vulnerability_finding_signatures) && !finding.signatures.empty?
        dismissal_feedback_by_finding_signatures(finding)
      else
        dismissal_feedback_by_project_fingerprint(finding)
      end
    end

    def all_dismissal_feedbacks
      strong_memoize(:all_dismissal_feedbacks) do
        pipeline.project
          .vulnerability_feedback
          .for_dismissal
      end
    end

    def dismissal_feedback_by_finding_signatures(finding)
      potential_uuids = Set.new([*finding.signature_uuids, finding.uuid].compact)
      all_dismissal_feedbacks.any? { |dismissal| potential_uuids.include?(dismissal.finding_uuid) }
    end

    def dismissal_feedback_by_fingerprint
      strong_memoize(:dismissal_feedback_by_fingerprint) do
        all_dismissal_feedbacks.group_by(&:project_fingerprint)
      end
    end

    def dismissal_feedback_by_project_fingerprint(finding)
      dismissal_feedback_by_fingerprint[finding.project_fingerprint]
    end

    def confidence_levels
      @confidence_levels ||= Array(params.fetch(:confidence, Vulnerabilities::Finding.confidences.keys))
    end

    def report_types
      @report_types ||= Array(params.fetch(:report_type, Vulnerabilities::Finding.report_types.keys))
    end

    def severity_levels
      @severity_levels ||= Array(params.fetch(:severity, Vulnerabilities::Finding.severities.keys))
    end

    def scanners
      @scanners ||= Array(params.fetch(:scanner, []))
    end

    def states
      @state ||= Array(params.fetch(:state, Vulnerability.states.keys))
    end
  end
end
