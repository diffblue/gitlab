# frozen_string_literal: true

module Security
  module Ingestion
    module Tasks
      # Links findings with pipelines by creating the
      # `Vulnerabilities::FindingPipeline` records.
      class IngestFindingPipelines < AbstractTask
        include Gitlab::Ingestion::BulkInsertableTask

        self.model = Vulnerabilities::FindingPipeline

        private

        def attributes
          finding_maps.map do |finding_map|
            { pipeline_id: pipeline.id, occurrence_id: finding_map.finding_id }
          end
        end
      end
    end
  end
end
