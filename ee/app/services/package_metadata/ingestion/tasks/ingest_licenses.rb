# frozen_string_literal: true

module PackageMetadata
  module Ingestion
    module Tasks
      class IngestLicenses < Base
        self.model = PackageMetadata::License
        self.unique_by = %i[spdx_identifier].freeze
        self.uses = %i[id spdx_identifier].freeze

        private

        def after_ingest
          return_data.each do |id, spdx_identifier|
            data_map.set_license_id(spdx_identifier, id)
          end
        end

        def attributes
          import_data.map do |data_object|
            { spdx_identifier: data_object.license }
          end
        end
      end
    end
  end
end
