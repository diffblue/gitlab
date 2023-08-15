# frozen_string_literal: true

module PackageMetadata
  module Ingestion
    module Advisory
      class AffectedPackageIngestionTask
        def initialize(import_data, advisory_map)
          @import_data = import_data
          @advisory_map = advisory_map
        end

        def self.execute(import_data, advisory_map)
          new(import_data, advisory_map).execute
        end

        def execute
          PackageMetadata::AffectedPackage.bulk_upsert!(valid_affected_packages,
            unique_by: %w[pm_advisory_id purl_type package_name distro_version])
        end

        private

        attr_reader :import_data, :advisory_map

        # validate checks the list of provided affected_package models and returns
        # only those which are valid and logs the invalid packages as an error
        def valid_affected_packages
          affected_packages.map do |affected_package|
            unless affected_package.valid?
              Gitlab::AppJsonLogger.error(class: self.class.name,
                message: "invalid affected_package",
                purl_type: affected_package.purl_type,
                package_name: affected_package.package_name,
                distro_version: affected_package.distro_version,
                errors: affected_package.errors.to_hash)
              next
            end

            affected_package
          end.reject(&:blank?)
        end

        def affected_packages
          import_data.flat_map do |data_object|
            data_object.affected_packages.map do |affected_package|
              PackageMetadata::AffectedPackage.new(
                purl_type: affected_package.purl_type,
                package_name: affected_package.package_name,
                solution: affected_package.solution,
                affected_range: affected_package.affected_range,
                fixed_versions: affected_package.fixed_versions,
                pm_advisory_id: advisory_map[data_object.advisory_xid],
                distro_version: affected_package.distro_version,
                versions: affected_package.versions,
                overridden_advisory_fields: affected_package.overridden_advisory_fields,
                created_at: now,
                updated_at: now
              )
            end
          end
        end

        def now
          @now ||= Time.zone.now
        end
      end
    end
  end
end
