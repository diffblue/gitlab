# frozen_string_literal: true

module Gitlab
  module LicenseScanning
    class PackageLicenses
      MAX_RECORDS_TO_FETCH = 1_000

      def initialize(components:)
        # TODO: update this to process components in batches.
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/388107
        if components.length > MAX_RECORDS_TO_FETCH
          raise ArgumentError, "Number of components (#{components.length}) is larger " \
                               "than the maximum allowed (#{MAX_RECORDS_TO_FETCH})"
        end

        @components = components[0..MAX_RECORDS_TO_FETCH]
      end

      def fetch
        # rubocop: disable CodeReuse/ActiveRecord
        search_fields = [
          PackageMetadata::Package.arel_table[:purl_type],
          PackageMetadata::Package.arel_table[:name],
          PackageMetadata::PackageVersion.arel_table[:version]
        ]

        component_tuples = components.map do |component|
          purl_type_int = ::Enums::Sbom.purl_types[component.purl_type]
          component_tuple = [purl_type_int, component.name, component.version].map { |c| Arel::Nodes.build_quoted(c) }
          Arel::Nodes::Grouping.new(component_tuple)
        end

        records = PackageMetadata::Package
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

      private

      attr_reader :components
    end
  end
end
