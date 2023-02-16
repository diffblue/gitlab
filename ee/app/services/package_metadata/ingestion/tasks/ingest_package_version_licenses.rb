# frozen_string_literal: true

module PackageMetadata
  module Ingestion
    module Tasks
      class IngestPackageVersionLicenses < Base
        self.model = PackageMetadata::PackageVersionLicense
        self.unique_by = %i[pm_package_version_id pm_license_id].freeze

        private

        def attributes
          import_data.map do |data_object|
            package_version_id = data_map.get_package_version_id(data_object.purl_type, data_object.name,
              data_object.version)
            license_id = data_map.get_license_id(data_object.license)
            { pm_package_version_id: package_version_id, pm_license_id: license_id }
          end
        end
      end
    end
  end
end
