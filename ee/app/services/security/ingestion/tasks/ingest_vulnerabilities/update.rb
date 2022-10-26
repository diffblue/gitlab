# frozen_string_literal: true

module Security
  module Ingestion
    module Tasks
      class IngestVulnerabilities
        # Updates the existing vulnerability records
        # by using a single database query.
        class Update < AbstractTask
          include Gitlab::Ingestion::BulkUpdatableTask

          self.model = Vulnerability

          private

          def attributes
            finding_maps.map { |finding_map| attributes_for(finding_map.vulnerability_id, finding_map.report_finding) }
          end

          def attributes_for(vulnerability_id, report_finding)
            {
              id: vulnerability_id,
              title: report_finding.name.truncate(::Issuable::TITLE_LENGTH_MAX),
              severity: report_finding.severity,
              confidence: report_finding.confidence,
              resolved_on_default_branch: false,
              updated_at: Time.zone.now,
              present_on_default_branch: true
            }
          end
        end
      end
    end
  end
end
