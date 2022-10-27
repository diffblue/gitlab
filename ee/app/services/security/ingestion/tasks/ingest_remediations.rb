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

        # In order to optimise remediation ingestion and permit concurrent execution of remediation ingestion.
        # The remediations are ingested via a Bulk Insert. This requires a new class to avoid implementing the
        # Carrierwave file upload instrumentation, as this doesn't work with the BulkInsertSafe module.
        # Context: https://gitlab.com/gitlab-org/gitlab/-/issues/362169
        class RemediationBulkInsertProxy < ApplicationRecord
          include BulkInsertSafe
          include ShaAttribute

          self.table_name = 'vulnerability_remediations'

          sha_attribute :checksum
        end

        delegate :project, to: :pipeline

        def after_ingest
          upload_remediations
          dissassociate_unfound_remediations
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
          @new_remediations ||= begin
            new_remediations = new_report_remediations.map do |remediation|
              RemediationBulkInsertProxy.new(
                summary: remediation.summary,
                checksum: remediation.checksum,
                file: remediation.diff_file.original_filename,
                project_id: project.id,
                created_at: Time.zone.now,
                updated_at: Time.zone.now
              )
            end

            new_remediation_ids = RemediationBulkInsertProxy.bulk_insert!(new_remediations, skip_duplicates: true, returns: :ids)

            Vulnerabilities::Remediation.id_in(new_remediation_ids)
          end
        end

        def upload_remediations
          new_remediations.each do |remediation|
            upload_remediation(remediation)
          end
        end

        def upload_remediation(remediation)
          new_report_remediations.find { _1.checksum == remediation.checksum }.then do |report_remediation|
            remediation.update(file: report_remediation.diff_file)
          end
        end

        def dissassociate_unfound_remediations
          Vulnerabilities::FindingRemediation.by_finding_id(finding_maps.map(&:finding_id))
                                             .id_not_in(return_data.flatten)
                                             .delete_all
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
