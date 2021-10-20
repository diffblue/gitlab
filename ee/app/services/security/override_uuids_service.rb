# frozen_string_literal: true

module Security
  class OverrideUuidsService
    def self.execute(security_report)
      new(security_report).execute
    end

    def initialize(security_report)
      @security_report = security_report
    end

    def execute
      return unless type.to_s == 'sast' && finding_signature_shas.present?

      findings.each { |finding| override_uuid_for(finding) }
    end

    private

    attr_reader :security_report

    delegate :pipeline, :findings, :type, to: :security_report

    def override_uuid_for(finding)
      existing_finding = existing_finding_by_signature(finding)

      if existing_finding
        finding.overridden_uuid = finding.uuid
        finding.uuid = existing_finding.uuid
      end
    end

    def existing_finding_by_signature(finding)
      shas = finding.signatures.sort_by(&:priority).map(&:signature_sha)

      existing_signatures.values_at(*shas).compact.map(&:finding).find do |existing_finding|
        existing_finding.primary_identifier&.fingerprint == finding.primary_identifier_fingerprint &&
          existing_finding.scanner == existing_scanners[finding.scanner.external_id]
      end
    end

    def existing_scanners
      @existing_scanners ||= pipeline.project.vulnerability_scanners.index_by(&:external_id)
    end

    def existing_signatures
      @existing_signatures ||= ::Vulnerabilities::FindingSignature.by_signature_sha(finding_signature_shas)
        .by_project(pipeline.project)
        .eager_load_comparison_entities
        .index_by(&:signature_sha)
    end

    def finding_signature_shas
      @finding_signature_shas ||= findings.flat_map(&:signatures).map(&:signature_sha)
    end
  end
end
