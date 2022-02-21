# frozen_string_literal: true

# This service stores the `Security::Scan` and
# `Security::Finding` records for the given job artifact.
#
# @param artifact [Ci::JobArtifact] the artifact to create scan and finding records from.
# @param known_keys [Set] the set of known finding keys stored by previous invocations of this service class.
# @param deduplicate [Boolean] attribute to force running deduplication logic.
module Security
  class StoreScanService
    DEDUPLICATE_BATCH_SIZE = 50

    def self.execute(artifact, known_keys, deduplicate)
      new(artifact, known_keys, deduplicate).execute
    end

    def initialize(artifact, known_keys, deduplicate)
      @artifact = artifact
      @known_keys = known_keys
      @deduplicate = deduplicate
    end

    def execute
      override_finding_uuids! if override_uuids?
      set_security_scan_non_latest! if job.retried?

      return deduplicate if security_scan.has_errors? || !security_scan.latest? || !security_scan.succeeded?

      store_findings
    end

    private

    attr_reader :artifact, :known_keys, :deduplicate

    delegate :project, :job, :security_report, to: :artifact, private: true

    def override_finding_uuids!
      OverrideUuidsService.execute(security_report)
    end

    def override_uuids?
      project.licensed_feature_available?(:vulnerability_finding_signatures)
    end

    def security_scan
      @security_scan ||= Security::Scan.safe_find_or_create_by!(build: job, scan_type: artifact.file_type) do |scan|
        scan.processing_errors = security_report.errors.map(&:stringify_keys) if security_report.errored?
        scan.status = job.success? ? :succeeded : :failed
      end
    end

    def store_findings
      StoreFindingsMetadataService.execute(security_scan, security_report, register_finding_keys).then do |result|
        # If `StoreFindingsMetadataService` returns error, it means the findings
        # have already been stored before so we may re-run the deduplication logic.
        update_deduplicated_findings if result[:status] == :error && deduplicate_findings?
      end

      deduplicate_findings?
    end

    def set_security_scan_non_latest!
      security_scan.update!(latest: false)
    end

    def deduplicate_findings?
      deduplicate || security_scan.saved_changes?
    end

    def update_deduplicated_findings
      Security::Scan.transaction do
        mark_all_findings_as_duplicate
        mark_unique_findings
      end
    end

    def mark_all_findings_as_duplicate
      security_scan.findings.deduplicated.each_batch(of: DEDUPLICATE_BATCH_SIZE) { |batch| batch.update_all(deduplicated: false) }
    end

    def mark_unique_findings
      register_finding_keys.each_slice(DEDUPLICATE_BATCH_SIZE) do |batch|
        security_scan.findings
                     .by_uuid(batch)
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
