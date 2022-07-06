# frozen_string_literal: true

module Security
  module Ingestion
    module Tasks
      # Creates new `Vulnerabilities::Finding::Evidence` records.
      class IngestFindingEvidence < AbstractTask
        include Gitlab::Ingestion::BulkInsertableTask

        self.model = Vulnerabilities::Finding::Evidence
        self.unique_by = :vulnerability_occurrence_id

        private

        def attributes
          finding_maps.select(&:evidence).map do |finding_map|
            {
              vulnerability_occurrence_id: finding_map.finding_id,
              data: finding_map.evidence.data
            }
          end
        end
      end
    end
  end
end
