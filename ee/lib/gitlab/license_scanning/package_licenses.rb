# frozen_string_literal: true

module Gitlab
  module LicenseScanning
    class PackageLicenses
      BATCH_SIZE = 700
      UNKNOWN_LICENSE = "unknown"

      def initialize(project:, components:)
        @components = components
        # component_data keeps track of the requested versions for each component, to
        # facilitate faster lookups by avoiding an O(n^2) search against the components array
        @component_data = Hash.new { |h, k| h[k] = [] }
        @project = project
        @all_records = {}
        @cached_licenses = []
      end

      def fetch
        return compressed_fetch if Feature.enabled?(:compressed_package_metadata_query, project)

        uncompressed_fetch
      end

      private

      attr_reader :components, :component_data, :all_records, :project, :cached_licenses

      # obtains licenses by using data from the `licenses` jsonb column in the pm_packages table to query
      # data from the pm_licenses table
      def compressed_fetch
        use_replica_if_available do
          init_all_records_to_unknown_licenses do |component|
            # build cache for faster lookups of licenses and component_version data
            build_component_data_cache(component)
          end

          # For each batch of components, we execute two queries:
          #
          # 1. Retrieve the packages for the components by querying the pm_packages table
          # 2. Use the data in the `licenses` jsonb column of the pm_packages table to
          #    lookup the corresponding licenses. This query is executed by the
          #    `package.licenses_for` method.
          components.each_slice(BATCH_SIZE).each do |components_batch|
            packages_for_batch = ::PackageMetadata::Package.packages_for(components: components_batch)

            packages_for_batch.each do |package|
              requested_data_for_package(package).each do |component|
                license_ids = package.license_ids_for(version: component[:version])

                add_record_with_known_licenses(purl_type: package.purl_type, name: package.name,
                  version: component[:version], license_ids: license_ids, path: component[:path])
              end
            end
          end

          all_records.values
        end
      end

      # obtains licenses by querying the pm_packages, pm_package_versions, pm_package_version_licenses
      # and pm_licenses tables
      def uncompressed_fetch
        use_replica_if_available do
          init_all_records_to_unknown_licenses do |component|
            # build cache for faster lookups of licenses and component_version data
            build_component_data_cache(component)
          end

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

          all_records.values
        end
      end

      def component_key(name:, version:, purl_type:)
        "#{name}/#{version}/#{purl_type}"
      end

      def component_data_key(name:, purl_type:)
        "#{name}/#{purl_type}"
      end

      # set the default license of all components to an unknown license.
      # If a license is eventually found for the component, we'll overwrite
      # the unknown entry with the valid license.
      # Initializing all records with an unknown license allows us to ensure
      # that the packages and licenses we return from the fetch method are the
      # same order as the components that were initially passed to the fetch
      # method. This allows callers to make assumptions about the ordering of
      # the data, which can simplify their code.
      def init_all_records_to_unknown_licenses
        components.each do |component|
          add_record_with_unknown_license(component)
          yield component if block_given?
        end
      end

      # we fetch package details from the pm_packages table which only contains the
      # purl_type and name. We need a way to know which versions were requested for
      # each purl_type and name, so we use a hash to store this data for faster lookups.
      def build_component_data_cache(component)
        component_data[component_data_key(name: component.name, purl_type: component.purl_type)] <<
          { version: component.version, path: component.path }
      end

      # there's only about 500 licenses in the pm_licenses table, and the data doesn't change often, so we use
      # a cache to avoid a separate sql query every time we need to convert from license_id to spdx_identifier.
      def spdx_id_for(license_id:)
        @pm_licenses ||= ::PackageMetadata::License.all.to_h { |license| [license.id, license.spdx_identifier] }
        @pm_licenses[license_id]
      end

      # there's only about 500 _valid_ licenses in the software_licenses table, and the data doesn't change often,
      # so we use a cache to avoid a separate sql query every time we need to convert from spdx_identifier to
      # license name.
      def license_name_for(spdx_id:)
        @software_licenses ||= SoftwareLicense.spdx.to_h { |license| [license.spdx_identifier, license.name] }
        @software_licenses[spdx_id] || spdx_id
      end

      def licenses_with_names_for(license_ids:)
        return [{ spdx_identifier: UNKNOWN_LICENSE, name: UNKNOWN_LICENSE }] if license_ids.blank?

        license_ids.map do |license_id|
          spdx_id = spdx_id_for(license_id: license_id)

          { spdx_identifier: spdx_id, name: license_name_for(spdx_id: spdx_id) }
        end
      end

      def requested_data_for_package(package)
        component_data[component_data_key(name: package.name, purl_type: package.purl_type)]
      end

      # Every time a license is encountered for a component, we record it.
      # This allows us to determine which components do not have licenses.
      # Adds a single record with known licenses. This method is used by both the
      # uncompressed and compressed queries.
      def add_record_with_known_licenses(purl_type:, name:, version:, license_ids:, path:)
        all_records[component_key(name: name, version: version, purl_type: purl_type)] =
          Hashie::Mash.new(purl_type: purl_type, name: name, version: version,
            licenses: licenses_with_names_for(license_ids: license_ids), path: path || '')
      end

      # Adds multiple records with known licenses
      def add_records_with_known_licenses(records)
        records.each do |purl_type, name, version, license_ids|
          components = component_data[component_data_key(name: name, purl_type: purl_type)]

          components.each do |component|
            next unless component[:version] == version

            add_record_with_known_licenses(purl_type: purl_type, name: name,
              version: version, license_ids: license_ids, path: component[:path])
          end
        end
      end

      def add_record_with_unknown_license(component)
        key = component_key(name: component.name, version: component.version, purl_type: component.purl_type)

        all_records[key] = Hashie::Mash.new(
          purl_type: component.purl_type, name: component.name, version: component.version,
          licenses: [{ spdx_identifier: UNKNOWN_LICENSE, name: UNKNOWN_LICENSE }])
      end

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

        # rubocop: disable CodeReuse/ActiveRecord
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
        # rubocop: enable CodeReuse/ActiveRecord

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

        # rubocop: disable CodeReuse/ActiveRecord
        ::PackageMetadata::Package
          .joins(package_versions: :licenses)
          .where(
            Arel::Nodes::In.new(
              Arel::Nodes::Grouping.new(package_id_and_version_fields),
              package_ids_and_versions
            )
          )
          .group(search_fields)
          .pluck(*search_fields, "ARRAY_AGG(pm_licenses.id)")
        # rubocop: enable CodeReuse/ActiveRecord
      end

      def use_replica_if_available(&block)
        ::Gitlab::Database::LoadBalancing::Session.current.use_replicas_for_read_queries(&block)
      end
    end
  end
end
