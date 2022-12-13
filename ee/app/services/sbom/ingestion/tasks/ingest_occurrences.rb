# frozen_string_literal: true

module Sbom
  module Ingestion
    module Tasks
      class IngestOccurrences < Base
        include Gitlab::Ingestion::BulkInsertableTask

        self.model = Sbom::Occurrence
        self.unique_by = :uuid
        self.uses = :id

        private

        def after_ingest
          return_data.each_with_index do |occurrence_id, index|
            occurrence_maps[index].occurrence_id = occurrence_id
          end
        end

        def attributes
          occurrence_maps.uniq! { |occurrence_map| uuid(occurrence_map) }
          occurrence_maps.map do |occurrence_map|
            {
              project_id: pipeline.project.id,
              pipeline_id: pipeline.id,
              component_id: occurrence_map.component_id,
              component_version_id: occurrence_map.component_version_id,
              source_id: occurrence_map.source_id,
              commit_sha: pipeline.sha,
              uuid: uuid(occurrence_map)
            }
          end
        end

        def uuid(occurrence_map)
          uuid_attributes = occurrence_map.to_h.slice(
            :component_id,
            :component_version_id,
            :source_id
          ).merge(project_id: pipeline.project.id)

          ::Sbom::OccurrenceUUID.generate(**uuid_attributes)
        end
      end
    end
  end
end
