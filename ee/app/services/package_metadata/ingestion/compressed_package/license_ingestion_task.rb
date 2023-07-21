# frozen_string_literal: true

module PackageMetadata
  module Ingestion
    module CompressedPackage
      class LicenseIngestionTask
        include ::Gitlab::Utils::StrongMemoize

        def initialize(import_data, license_map)
          @import_data = import_data
          @license_map = license_map
        end

        def self.execute(import_data, license_map)
          new(import_data, license_map).execute
        end

        def execute
          license_map.merge!(existing_licenses)

          result = PackageMetadata::License.bulk_upsert!(new_licenses, unique_by: ['spdx_identifier'],
            returns: %w[spdx_identifier id])

          license_map.merge!(result.to_h)
        end

        private

        attr_reader :import_data
        attr_accessor :license_map

        def spdx_identifiers
          import_data.flat_map(&:spdx_identifiers).sort.uniq
        end
        strong_memoize_attr :spdx_identifiers

        def existing_licenses
          PackageMetadata::License.with_spdx_identifiers(spdx_identifiers)
            .to_h { |license| [license.spdx_identifier, license.id] }
        end

        def new_licenses
          spdx_identifiers
            .reject { |id| license_map[id] }
            .map { |id| build(id) }
        end

        def build(spdx_identifier)
          PackageMetadata::License.new(spdx_identifier: spdx_identifier, created_at: now, updated_at: now)
        end

        def now
          @now ||= Time.zone.now
        end
      end
    end
  end
end
