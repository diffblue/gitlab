# frozen_string_literal: true

module Sbom
  module Ingestion
    module Tasks
      class IngestComponents < Base
        include Gitlab::Ingestion::BulkInsertableTask

        COMPONENT_ATTRIBUTES = %i[component_type name].freeze

        self.model = Sbom::Component
        self.unique_by = COMPONENT_ATTRIBUTES
        self.uses = %i[component_type name id].freeze

        private

        def after_ingest
          return_data.each do |component_type, name, id|
            maps_with(component_type, name)&.each do |occurrence_map|
              occurrence_map.component_id = id
            end
          end
        end

        def attributes
          occurrence_maps.map do |occurrence_map|
            occurrence_map.to_h.slice(*COMPONENT_ATTRIBUTES)
          end
        end

        def maps_with(component_type, name)
          grouped_maps[[component_type, name]]
        end

        def grouped_maps
          @grouped_maps ||= occurrence_maps.group_by do |occurrence_map|
            report_component = occurrence_map.report_component

            [report_component.component_type, report_component.name]
          end
        end
      end
    end
  end
end
