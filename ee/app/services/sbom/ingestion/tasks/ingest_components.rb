# frozen_string_literal: true

module Sbom
  module Ingestion
    module Tasks
      class IngestComponents < Base
        include Gitlab::Ingestion::BulkInsertableTask

        COMPONENT_ATTRIBUTES = %i[name purl_type component_type].freeze

        self.model = Sbom::Component
        self.unique_by = COMPONENT_ATTRIBUTES
        self.uses = %i[id name purl_type component_type].freeze

        private

        def after_ingest
          return_data.each do |id, name, purl_type, component_type|
            maps_with(name, purl_type, component_type)&.each do |occurrence_map|
              occurrence_map.component_id = id
            end
          end
        end

        def attributes
          occurrence_maps.map do |occurrence_map|
            occurrence_map.to_h.slice(*COMPONENT_ATTRIBUTES)
          end
        end

        def maps_with(name, purl_type, component_type)
          grouped_maps[[name, purl_type, component_type]]
        end

        def grouped_maps
          @grouped_maps ||= occurrence_maps.group_by do |occurrence_map|
            occurrence_map.to_h.values_at(:name, :purl_type, :component_type)
          end
        end
      end
    end
  end
end
