# frozen_string_literal: true

module PackageMetadata
  module Ingestion
    module CompressedPackage
      class IngestionService
        def self.execute(import_data)
          new(import_data).execute
        end

        def initialize(import_data)
          @import_data = import_data
          @license_map = {}
        end

        def execute
          ApplicationRecord.transaction do
            ingest_licenses
            ingest_packages
          end
        end

        private

        def ingest_licenses
          LicenseIngestionTask.execute(import_data, license_map)
        end

        def ingest_packages
          PackageIngestionTask.execute(import_data, license_map)
        end

        attr_reader :import_data, :license_map
      end
    end
  end
end
