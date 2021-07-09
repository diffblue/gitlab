# frozen_string_literal: true

# This service stores the `Security::Scan` and
# `Security::Finding` records for the given job artifact.
#
# @param artifact [Ci::JobArtifact] the artifact to create scan and finding records from.
# @param known_keys [Set] the set of known finding keys stored by previous invocations of this service class.
# @param deduplicate [Boolean] attribute to force running deduplication logic.
module Security
  class StoreScanService
    def self.execute(artifact, known_keys, deduplicate)
      new(artifact, known_keys, deduplicate).execute
    end

    def initialize(artifact, known_keys, deduplicate)
      @artifact = artifact
      @known_keys = known_keys
      @deduplicate = deduplicate
    end

    def execute
      return deduplicate if security_scan.has_errors?

      StoreFindingsMetadataService.execute(security_scan, security_report)
      deduplicate_findings? ? update_deduplicated_findings : register_finding_keys

      deduplicate_findings?
    end

    private

    attr_reader :artifact, :known_keys, :deduplicate
    delegate :security_report, :project, to: :artifact, private: true

    def security_scan
      @security_scan ||= Security::Scan.safe_find_or_create_by!(build: artifact.job, scan_type: artifact.file_type) do |scan|
        scan.info['errors'] = security_report.errors.map(&:stringify_keys) if security_report.errored?
      end
    end

    def deduplicate_findings?
      deduplicate || security_scan.saved_changes?
    end

    def update_deduplicated_findings
      Security::Scan.transaction do
        security_scan.findings.update_all(deduplicated: false)

        security_scan.findings
                     .by_uuid(register_finding_keys)
                     .update_all(deduplicated: true)
      end
    end

    # This method registers all finding keys and
    # returns the UUIDs of the unique findings
    def register_finding_keys
      @register_finding_keys ||= security_report.findings.map { |finding| register_keys(finding.keys) && finding.uuid }.compact
    end

    def register_keys(keys)
      return if known_keys.intersect?(keys.to_set)

      known_keys.merge(keys)
    end
  end
end
