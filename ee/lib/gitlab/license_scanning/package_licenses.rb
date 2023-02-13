# frozen_string_literal: true

module Gitlab
  module LicenseScanning
    class PackageLicenses
      BATCH_SIZE = 700
      UNKNOWN_LICENSE = "unknown"

      def initialize(components:)
        @components = components
      end

      def fetch
        search_fields = [
          ::PackageMetadata::Package.arel_table[:purl_type],
          ::PackageMetadata::Package.arel_table[:name],
          ::PackageMetadata::PackageVersion.arel_table[:version]
        ]

        records_with_licenses = {}

        components.each_slice(BATCH_SIZE).each do |components_batch|
          # rubocop: disable CodeReuse/ActiveRecord
          component_tuples = components_batch.map do |component|
            purl_type_int = ::Enums::Sbom.purl_types[component.purl_type]
            component_tuple = [purl_type_int, component.name, component.version].map { |c| Arel::Nodes.build_quoted(c) }
            Arel::Nodes::Grouping.new(component_tuple)
          end

          records_for_batch = ::PackageMetadata::Package
                      .joins(package_versions: :licenses)
                      .where(
                        Arel::Nodes::In.new(
                          Arel::Nodes::Grouping.new(search_fields),
                          component_tuples
                        )
                      )
                      .group(search_fields)
                      .pluck(*search_fields, "ARRAY_AGG(pm_licenses.spdx_identifier)")
          # rubocop: enable CodeReuse/ActiveRecord

          records_for_batch.each do |purl_type, name, version, licenses|
            records_with_licenses[File.join(name, version, purl_type)] =
              Hashie::Mash.new(purl_type: purl_type, name: name, version: version, licenses: licenses)
          end
        end

        add_records_with_unknown_licenses(records_with_licenses)
        records_with_licenses.values
      end

      private

      attr_reader :components

      def add_records_with_unknown_licenses(records_with_licenses)
        components.each do |component|
          key = File.join(component.name, component.version, component.purl_type)
          next if records_with_licenses[key]

          # return unknown license if the license data for the component wasn't found in the db
          records_with_licenses[key] = Hashie::Mash.new(purl_type: component.purl_type,
            name: component.name, version: component.version, licenses: [UNKNOWN_LICENSE])
        end
      end
    end
  end
end
