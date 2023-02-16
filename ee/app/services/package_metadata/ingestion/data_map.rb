# frozen_string_literal: true

module PackageMetadata
  module Ingestion
    class DataMap
      attr_reader :import_data

      def initialize(import_data)
        @import_data = import_data
      end

      def get_package_id(purl_type, name)
        packages[[purl_type, name]]&.first&.package_id
      end

      def set_package_id(purl_type, name, id)
        packages[[purl_type, name]].each do |data_object|
          data_object.package_id = id
        end
      end

      def get_package_version_id(purl_type, name, version)
        package_id = get_package_id(purl_type, name)
        versions[[package_id, version]]&.first&.package_version_id
      end

      def set_package_version_id(pm_package_id, version, id)
        versions[[pm_package_id, version]].each do |data_object|
          data_object.package_version_id = id
        end
      end

      def get_license_id(spdx_identifier)
        licenses[spdx_identifier].first&.license_id
      end

      def set_license_id(spdx_identifier, id)
        licenses[spdx_identifier]&.each do |data_object|
          data_object.license_id = id
        end
      end

      private

      def packages
        @packages ||= import_data.group_by { |object| [object.purl_type, object.name] }
      end

      def versions
        @versions ||= import_data.group_by { |object| [object.package_id, object.version] }
      end

      def licenses
        @licenses ||= import_data.group_by(&:license)
      end
    end
  end
end
