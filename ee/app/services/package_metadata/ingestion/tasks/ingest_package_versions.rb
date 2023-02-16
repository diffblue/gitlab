# frozen_string_literal: true

module PackageMetadata
  module Ingestion
    module Tasks
      class IngestPackageVersions < Base
        self.model = PackageMetadata::PackageVersion
        self.unique_by = %i[pm_package_id version].freeze
        self.uses = %i[id pm_package_id version].freeze

        private

        def after_ingest
          return_data.each do |id, pm_package_id, version|
            data_map.set_package_version_id(pm_package_id, version, id)
          end
        end

        def attributes
          import_data.map do |data_object|
            pm_package_id = data_map.get_package_id(data_object.purl_type, data_object.name)
            { pm_package_id: pm_package_id, version: data_object.version }
          end
        end
      end
    end
  end
end
