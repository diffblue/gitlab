# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module DropInvalidRemediations
        class Finding < ActiveRecord::Base
          self.table_name = 'vulnerability_occurrences'
        end

        class FindingRemediation < ActiveRecord::Base
          include ::EachBatch

          belongs_to :finding, class_name: '::Gitlab::BackgroundMigration::DropInvalidRemediations::Finding'
          self.table_name = 'vulnerability_findings_remediations'
        end

        def perform(start_id, end_id)
          finding_remediation_batch = FindingRemediation.where(id: start_id..end_id)
          findings_without_remediation_ids = []
          Finding.where(id: finding_remediation_batch.select(:vulnerability_occurrence_id)).each do |finding|
            findings_without_remediation_ids << finding.id if empty_remediations?(finding)
          end

          remediations_to_destroy = finding_remediation_batch.select { |finding_remediation| findings_without_remediation_ids.include? finding_remediation.vulnerability_occurrence_id }

          FindingRemediation.where(id: remediations_to_destroy).each_batch(of: 100) do |batch|
            batch.delete_all
          end

          mark_job_as_succeeded(start_id, end_id)
        end

        private

        def empty_remediations?(finding)
          ::Gitlab::Json.parse(finding[:raw_metadata])["remediations"] == [nil]
        rescue StandardError
          false
        end

        def mark_job_as_succeeded(*arguments)
          ::Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
            self.class.name.demodulize,
            arguments
          )
        end
      end
    end
  end
end
