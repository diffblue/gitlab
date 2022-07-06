# frozen_string_literal: true

module Security
  module Ingestion
    module Tasks
      # Updates the `vulnerability_id` attribute of finding records.
      class AttachFindingsToVulnerabilities < AbstractTask
        include Gitlab::Ingestion::BulkUpdatableTask

        self.model = Vulnerabilities::Finding

        private

        def attributes
          new_finding_maps.map { |finding_map| attributes_for(finding_map) }
        end

        def new_finding_maps
          @new_finding_maps ||= finding_maps.select(&:new_record)
        end

        def attributes_for(finding_map)
          {
            id: finding_map.finding_id,
            vulnerability_id: finding_map.vulnerability_id
          }
        end
      end
    end
  end
end
