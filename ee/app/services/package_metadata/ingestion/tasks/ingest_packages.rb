# frozen_string_literal: true

module PackageMetadata
  module Ingestion
    module Tasks
      class IngestPackages < Base
        include Gitlab::Ingestion::BulkInsertableTask

        self.model = PackageMetadata::Package
        self.unique_by = %i[purl_type name].freeze
        self.uses = %i[id purl_type name].freeze

        private

        def after_ingest
          return_data.each do |id, purl_type, name|
            data_map.set_package_id(purl_type, name, id)
          end
        end

        def attributes
          import_data.map do |data_object|
            { purl_type: data_object.purl_type, name: data_object.name }
          end
        end
      end
    end
  end
end
