# frozen_string_literal: true

module Gitlab
  module LicenseScanning
    class PackageLicenses
      BATCH_SIZE = 700

      def initialize(components:)
        @components = components
      end

      def fetch
        search_fields = [
          ::PackageMetadata::Package.arel_table[:purl_type],
          ::PackageMetadata::Package.arel_table[:name],
          ::PackageMetadata::PackageVersion.arel_table[:version]
        ]

        components.each_slice(BATCH_SIZE).flat_map do |components_batch|
          # rubocop: disable CodeReuse/ActiveRecord
          component_tuples = components_batch.map do |component|
            purl_type_int = ::Enums::Sbom.purl_types[component.purl_type]
            component_tuple = [purl_type_int, component.name, component.version].map { |c| Arel::Nodes.build_quoted(c) }
            Arel::Nodes::Grouping.new(component_tuple)
          end

          records = ::PackageMetadata::Package
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

          records.map do |purl_type, name, version, licenses|
            Hashie::Mash.new(purl_type: purl_type, name: name, version: version, licenses: licenses)
          end
        end
      end

      private

      attr_reader :components
    end
  end
end
