# frozen_string_literal: true

# Calibrates the UUID values of findings by trying to
# find an existing `Vulnerabilities::Finding` with one of the
# following approaches:
#
# 1) By using finding signatures
# 2) By using the location information
module Security
  class OverrideUuidsService
    BATCH_SIZE = 100

    def self.execute(security_report)
      new(security_report).execute
    end

    def initialize(security_report)
      @security_report = security_report
      @known_uuids = findings.map(&:uuid).to_set
    end

    def execute
      return unless type.to_s == 'sast' && has_signatures?

      findings.each_slice(BATCH_SIZE) { |batch| OverrideInBatch.execute(project, batch, existing_scanners, known_uuids) }

      # This sorting will make sure that the existing findings will be processed
      # before the new findings to prevent collision on the following unique index;
      # (project_id, primary_identifier_id, location_fingerprint, scanner_id)
      findings.sort! { |a, b| b.overridden_uuid.to_s <=> a.overridden_uuid.to_s }
    end

    # We need to run the UUID override logic
    # in batches to prevent loading too many records
    # at once into the memory.
    class OverrideInBatch
      def self.execute(project, findings, scanners, known_uuids)
        new(project, findings, scanners, known_uuids).execute
      end

      def initialize(project, findings, scanners, known_uuids)
        @project = project
        @findings = findings
        @scanners = scanners
        @known_uuids = known_uuids
      end

      def execute
        findings.each { |finding| override_uuid_for(finding) }
      end

      private

      attr_reader :project, :findings, :scanners, :known_uuids

      def override_uuid_for(finding)
        existing_finding = existing_finding_by_signature(finding) || existing_finding_by_location(finding)

        if existing_finding && known_uuids.add?(existing_finding.uuid)
          finding.overridden_uuid = finding.uuid
          finding.uuid = existing_finding.uuid
        end
      end

      # This method tries to find an existing finding by signatures
      # in case if a new algorithm is introduced or if there is a finding
      # with the UUID calculated by the location information.
      def existing_finding_by_signature(finding)
        shas = finding.signatures.sort_by(&:priority).map(&:signature_sha)

        existing_signatures.values_at(*shas).compact.map(&:finding).find do |existing_finding|
          compare_with_existing_finding(existing_finding, finding)
        end
      end

      # This method should be called when a project starts using
      # the finding signatures for the first time.
      def existing_finding_by_location(finding)
        return unless finding.has_signatures? && finding.location

        existing_findings_by_location[finding.location.fingerprint].to_a.find do |existing_finding|
          compare_with_existing_finding(existing_finding, finding)
        end
      end

      def compare_with_existing_finding(existing_finding, finding)
        existing_finding.primary_identifier&.fingerprint == finding.primary_identifier_fingerprint &&
          existing_finding.scanner == scanners[finding.scanner.external_id]
      end

      def existing_signatures
        @existing_signatures ||= ::Vulnerabilities::FindingSignature.by_signature_sha(finding_signature_shas)
          .by_project(project)
          .eager_load_comparison_entities
          .index_by(&:signature_sha)
      end

      def finding_signature_shas
        @finding_signature_shas ||= findings.flat_map(&:signatures).map(&:signature_sha)
      end

      def existing_findings_by_location
        @existing_findings_by_location ||= project.vulnerability_findings
                                                  .sast
                                                  .by_location_fingerprints(location_fingerprints)
                                                  .eager_load_comparison_entities
                                                  .group_by(&:location_fingerprint)
      end

      def location_fingerprints
        findings.map(&:location).compact.map(&:fingerprint)
      end
    end

    private

    attr_reader :security_report, :known_uuids

    delegate :pipeline, :findings, :type, :has_signatures?, to: :security_report, private: true
    delegate :project, to: :pipeline, private: true

    def existing_scanners
      # Reloading the scanners will make sure that the collection proxy will be up-to-date.
      @existing_scanners ||= project.vulnerability_scanners.reset.index_by(&:external_id)
    end
  end
end
