# frozen_string_literal: true

module Sbom
  module Ingestion
    module Tasks
      class IngestOccurrences < Base
        include Gitlab::Ingestion::BulkInsertableTask

        self.model = Sbom::Occurrence
        self.unique_by = %i[
          project_id
          component_id
          component_version_id
          source_id
          commit_sha
        ].freeze

        private

        def attributes
          occurrence_maps.map do |occurrence_map|
            {
              project_id: pipeline.project.id,
              pipeline_id: pipeline.id,
              component_id: occurrence_map.component_id,
              component_version_id: occurrence_map.component_version_id,
              source_id: occurrence_map.source_id,
              commit_sha: pipeline.sha
            }
          end
        end
      end
    end
  end
end
