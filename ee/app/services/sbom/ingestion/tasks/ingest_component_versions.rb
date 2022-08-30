# frozen_string_literal: true

module Sbom
  module Ingestion
    module Tasks
      class IngestComponentVersions < Base
        include Gitlab::Ingestion::BulkInsertableTask

        COMPONENT_VERSION_ATTRIBUTES = %i[component_id version].freeze

        self.model = Sbom::ComponentVersion
        self.unique_by = COMPONENT_VERSION_ATTRIBUTES
        self.uses = :id

        private

        def valid_occurrence_maps
          @valid_occurrence_maps ||= occurrence_maps.filter(&:version_present?)
        end

        def after_ingest
          return_data.each_with_index do |component_version_id, index|
            occurrence_map = valid_occurrence_maps[index]

            occurrence_map.component_version_id = component_version_id
          end
        end

        def attributes
          valid_occurrence_maps.map do |occurrence_map|
            occurrence_map.to_h.slice(*COMPONENT_VERSION_ATTRIBUTES)
          end
        end
      end
    end
  end
end
