# frozen_string_literal: true

module Sbom
  module Ingestion
    module Tasks
      class IngestComponentVersions < Base
        include Gitlab::Ingestion::BulkInsertableTask

        COMPONENT_VERSION_ATTRIBUTES = %i[component_id version].freeze

        self.model = Sbom::ComponentVersion
        self.unique_by = COMPONENT_VERSION_ATTRIBUTES
        self.uses = %i[id component_id version].freeze

        private

        def after_ingest
          return_data.each do |component_version_id, component_id, version|
            maps_with(component_id, version)&.each do |occurrence_map|
              occurrence_map.component_version_id = component_version_id
            end
          end
        end

        def attributes
          valid_occurrence_maps.map do |occurrence_map|
            occurrence_map.to_h.slice(*COMPONENT_VERSION_ATTRIBUTES)
          end
        end

        def valid_occurrence_maps
          @valid_occurrence_maps ||= occurrence_maps.filter(&:version_present?)
        end

        def maps_with(component_id, version)
          grouped_maps[[component_id, version]]
        end

        def grouped_maps
          @grouped_maps ||= valid_occurrence_maps.group_by do |occurrence_map|
            report_component = occurrence_map.report_component

            [occurrence_map.component_id, report_component.version]
          end
        end
      end
    end
  end
end
