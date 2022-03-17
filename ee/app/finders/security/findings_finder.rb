# frozen_string_literal: true

# Security::FindingsFinder
#
# Used to find Ci::Builds associated with requested findings.
#
# Arguments:
#   pipeline - object to filter findings
#   params:
#     severity:    Array<String>
#     confidence:  Array<String>
#     report_type: Array<String>
#     scope:       String
#     page:        Int
#     per_page:    Int

module Security
  class FindingsFinder
    ResultSet = Struct.new(:relation, :findings) do
      delegate :current_page, :limit_value, :total_pages, :total_count, :next_page, :prev_page, to: :relation
    end

    DEFAULT_PAGE = 1
    DEFAULT_PER_PAGE = 20

    def initialize(pipeline, params: {})
      @pipeline = pipeline
      @params = params
    end

    def execute
      return unless has_security_findings?

      ResultSet.new(security_findings, findings)
    end

    private

    attr_reader :pipeline, :params

    delegate :project, :has_security_findings?, to: :pipeline, private: true

    def findings
      security_findings.map(&method(:build_vulnerability_finding))
    end

    def build_vulnerability_finding(security_finding)
      report_finding = report_finding_for(security_finding)
      return Vulnerabilities::Finding.new unless report_finding

      finding_data = report_finding.to_hash.except(:compare_key, :identifiers, :location, :scanner, :links, :signatures, :flags, :evidence)
      identifiers = report_finding.identifiers.map do |identifier|
        Vulnerabilities::Identifier.new(identifier.to_hash)
      end
      signatures = report_finding.signatures.map do |signature|
        Vulnerabilities::FindingSignature.new(signature.to_hash)
      end
      evidence = Vulnerabilities::Finding::Evidence.new(data: report_finding.evidence.data) if report_finding.evidence

      Vulnerabilities::Finding.new(finding_data).tap do |finding|
        finding.location_fingerprint = report_finding.location.fingerprint
        finding.vulnerability = vulnerability_for(security_finding)
        finding.project = project
        finding.sha = pipeline.sha
        finding.scanner = security_finding.scanner
        finding.finding_evidence = evidence

        if calculate_false_positive?
          finding.vulnerability_flags = report_finding.flags.map do |flag|
            Vulnerabilities::Flag.new(flag)
          end
        end

        finding.identifiers = identifiers
        finding.signatures = signatures
      end
    end

    def report_finding_for(security_finding)
      lookup_uuid = security_finding.overridden_uuid || security_finding.uuid

      report_findings.dig(security_finding.build.id, lookup_uuid)
    end

    def vulnerability_for(security_finding)
      existing_vulnerabilities.dig(security_finding.scan.scan_type, security_finding.project_fingerprint)&.first
    end

    def calculate_false_positive?
      project.licensed_feature_available?(:sast_fp_reduction)
    end

    def existing_vulnerabilities
      @existing_vulnerabilities ||= begin
        project.vulnerabilities
               .with_findings
               .with_report_types(loaded_report_types)
               .by_project_fingerprints(loaded_project_fingerprints)
               .group_by(&:report_type)
               .transform_values { |vulnerabilties| vulnerabilties.group_by { |v| v.finding.project_fingerprint } }
      end
    end

    def loaded_report_types
      security_findings.map(&:scan_type).uniq
    end

    def loaded_project_fingerprints
      security_findings.map(&:project_fingerprint)
    end

    def report_findings
      @report_findings ||= begin
        builds.each_with_object({}) do |build, memo|
          reports = build.job_artifacts.map(&:security_report).compact
          next unless reports.present?

          memo[build.id] = reports.flat_map(&:findings).index_by(&:uuid)
        end
      end
    end

    def builds
      security_findings.map(&:build).uniq
    end

    def security_findings
      @security_findings ||= include_dismissed? ? all_security_findings : all_security_findings.undismissed
    end

    def all_security_findings
      pipeline.security_findings
              .with_pipeline_entities
              .with_scan
              .with_scanner
              .deduplicated
              .ordered
              .latest
              .page(page)
              .per(per_page)
              .then(&method(:by_confidence_levels))
              .then(&method(:by_report_types))
              .then(&method(:by_severity_levels))
    end

    def per_page
      @per_page ||= params[:per_page] || DEFAULT_PER_PAGE
    end

    def page
      @page ||= params[:page] || DEFAULT_PAGE
    end

    def include_dismissed?
      params[:scope] == 'all'
    end

    def by_confidence_levels(relation)
      return relation unless params[:confidence]

      relation.by_confidence_levels(params[:confidence])
    end

    def by_report_types(relation)
      return relation unless params[:report_type]

      relation.by_report_types(params[:report_type])
    end

    def by_severity_levels(relation)
      return relation unless params[:severity]

      relation.by_severity_levels(params[:severity])
    end
  end
end
