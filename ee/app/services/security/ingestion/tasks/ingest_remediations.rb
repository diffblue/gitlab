# frozen_string_literal: true

module Security
  module Ingestion
    module Tasks
      # Creates Vulnerabilities::Remediation records for the new remediations
      # and updates the Vulnerabilities::FindingRemediation records.
      class IngestRemediations < AbstractTask
        include Gitlab::Ingestion::BulkInsertableTask

        self.model = Vulnerabilities::FindingRemediation
        self.unique_by = %i[vulnerability_occurrence_id vulnerability_remediation_id]
        self.uses = :id

        private

        delegate :project, to: :pipeline

        def after_ingest
          Vulnerabilities::FindingRemediation.by_finding_id(finding_maps.map(&:finding_id))
                                             .id_not_in(return_data.flatten)
                                             .delete_all
        end

        def attributes
          finding_maps.flat_map do |finding_map|
            remediations_for(finding_map.report_finding).map do |remediation|
              {
                vulnerability_occurrence_id: finding_map.finding_id,
                vulnerability_remediation_id: remediation.id
              }
            end
          end
        end

        def remediations_for(report_finding)
          checksums = report_finding.remediations.map(&:checksum)

          return [] unless checksums.present?

          all_remediations.select { |remediation| checksums.include?(remediation.checksum) }
        end

        def all_remediations
          @all_remediations ||= new_remediations + existing_remediations
        end

        def new_remediations
          new_report_remediations.map do |remediation|
            project.vulnerability_remediations.create(summary: remediation.summary, file: remediation.diff_file, checksum: remediation.checksum)
          end
        end

        def new_report_remediations
          existing_remediation_checksums = existing_remediations.map(&:checksum)

          report_remediations.select { |remediation| !existing_remediation_checksums.include?(remediation.checksum) }
        end

        def existing_remediations
          @existing_remediations ||= project.vulnerability_remediations.by_checksum(report_remediations.map(&:checksum)).to_a
        end

        def report_remediations
          @report_remediations ||= finding_maps.map(&:report_finding).flat_map(&:remediations).uniq(&:checksum)
        end
      end
    end
  end
end
