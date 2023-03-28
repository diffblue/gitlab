# frozen_string_literal: true

module Gitlab
  module LicenseScanning
    class PackageLicenses
      BATCH_SIZE = 700
      UNKNOWN_LICENSE = "unknown"

      def initialize(components:)
        @components = components
        @all_records = {}
      end

      def fetch
        use_replica_if_available do
          # For each batch of components, we execute two queries:
          #
          # 1. retrieve the package ids and versions for the components by using a CTE with purl_type and name
          # 2. use the package ids and versions to retrieve the licenses
          #
          # See this comment for more details: https://gitlab.com/gitlab-org/gitlab/-/issues/398679#note_1326528991
          components.each_slice(BATCH_SIZE).each do |components_batch|
            package_ids_and_versions_for_batch = get_package_ids_and_versions(components_batch)
            records_with_licenses_for_batch = get_records_with_licenses(package_ids_and_versions_for_batch)
            add_records_with_known_licenses(records_with_licenses_for_batch)
          end

          add_records_with_unknown_licenses
          all_records.values
        end
      end

      private

      attr_reader :components, :all_records

      # Every time a license is encountered for a component, we record it.
      # This allows us to determine which components do not have licenses.
      def add_records_with_known_licenses(records)
        records.each do |purl_type, name, version, licenses|
          component_key = File.join(name, version, purl_type)
          all_records[component_key] =
            Hashie::Mash.new(purl_type: purl_type, name: name, version: version, licenses: licenses)
        end
      end

      # Check to see if a license exists for each component. Record 'unknown' license for
      # components that do not have a license.
      def add_records_with_unknown_licenses
        components.each do |component|
          component_key = File.join(component.name || '', component.version || '', component.purl_type || '')
          next if all_records[component_key]

          # record unknown license if the license data for the component wasn't found in the db
          all_records[component_key] = Hashie::Mash.new(purl_type: component.purl_type,
            name: component.name, version: component.version, licenses: [UNKNOWN_LICENSE])
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord

      # Takes an array of components containing purl_type, name, and version fields and returns an array
      # containing package_id, version fields for each matching purl_type and name.
      def get_package_ids_and_versions(components)
        pm_packages_table = ::PackageMetadata::Package.arel_table
        needed_package_versions_table = Arel::Table.new(:needed_package_versions)

        component_tuples = components.map do |component|
          purl_type_int = ::Enums::Sbom.purl_types[component.purl_type]
          [purl_type_int, component.name, component.version]
        end

        component_values_list = Arel::Nodes::Grouping.new(Arel::Nodes::ValuesList.new(component_tuples))

        cte_query = Arel::Nodes::As.new(
          # The (purl_type, name, version) arguments in the following statement are known as
          # "External Aliases". Arel doesn't seem to have native support for external aliases,
          # so we had to use a workaround which assigns the sql string to the 'name' method.
          Hashie::Mash.new(
            name: Arel.sql('needed_package_versions(purl_type, name, version)')), component_values_list
        )

        package_ids_and_versions_query = needed_package_versions_table
          .project(pm_packages_table[:id], needed_package_versions_table[:version])
          .with(cte_query)
          .distinct
          .join(pm_packages_table)
          .on(
            pm_packages_table[:purl_type].eq(needed_package_versions_table[:purl_type])
              .and(
                pm_packages_table[:name].eq(needed_package_versions_table[:name]))
          )

        package_ids_and_versions = ApplicationRecord.connection.execute(package_ids_and_versions_query.to_sql)

        package_ids_and_versions.map do |package_id_and_version|
          Arel::Nodes::Grouping.new([
            Arel::Nodes.build_quoted(package_id_and_version['id']),
            Arel::Nodes.build_quoted(package_id_and_version['version'])
          ])
        end
      end

      # Takes an array of package id and version pairs, for example:
      # [(157839, '0.2.4'), (770517, '1.3.0')]
      # and returns an array of arrays, where each element contains purl_type, name, version, [licenses], for example:
      # [["golang", "beego", "v1.10.0", ["OLDAP-2.1", "OLDAP-2.2"]], ["golang", "cliui", "2.1.0", ["OLDAP-2.6"]]]
      def get_records_with_licenses(package_ids_and_versions)
        package_id_and_version_fields = [
          ::PackageMetadata::PackageVersion.arel_table[:pm_package_id],
          ::PackageMetadata::PackageVersion.arel_table[:version]
        ]

        search_fields = [
          ::PackageMetadata::Package.arel_table[:purl_type],
          ::PackageMetadata::Package.arel_table[:name],
          ::PackageMetadata::PackageVersion.arel_table[:version]
        ]

        ::PackageMetadata::Package
          .joins(package_versions: :licenses)
          .where(
            Arel::Nodes::In.new(
              Arel::Nodes::Grouping.new(package_id_and_version_fields),
              package_ids_and_versions
            )
          )
          .group(search_fields)
          .pluck(*search_fields, "ARRAY_AGG(pm_licenses.spdx_identifier)")
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def use_replica_if_available(&block)
        ::Gitlab::Database::LoadBalancing::Session.current.use_replicas_for_read_queries(&block)
      end
    end
  end
end
