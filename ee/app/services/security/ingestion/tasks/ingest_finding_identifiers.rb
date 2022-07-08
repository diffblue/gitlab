# frozen_string_literal: true

module Security
  module Ingestion
    module Tasks
      # Links findings with identifiers by creating the
      # `Vulnerabilities::FindingIdentifier` records.
      class IngestFindingIdentifiers < AbstractTask
        include Gitlab::Ingestion::BulkInsertableTask

        self.model = Vulnerabilities::FindingIdentifier
        self.unique_by = %i[occurrence_id identifier_id].freeze

        private

        def attributes
          finding_maps.flat_map do |finding_map|
            finding_map.identifier_ids.map do |identifier_id|
              {
                occurrence_id: finding_map.finding_id,
                identifier_id: identifier_id
              }
            end
          end
        end
      end
    end
  end
end
