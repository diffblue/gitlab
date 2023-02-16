# frozen_string_literal: true

module PackageMetadata
  module Ingestion
    class IngestionService
      TASKS = [
        Tasks::IngestPackages,
        Tasks::IngestPackageVersions,
        Tasks::IngestLicenses,
        Tasks::IngestPackageVersionLicenses
      ].freeze

      def self.execute(import_data)
        new(import_data).execute
      end

      def initialize(import_data)
        @data_map = DataMap.new(import_data)
      end

      def execute
        ApplicationRecord.transaction do
          TASKS.each { |t| t.execute(data_map) }
        end
      end

      private

      attr_reader :import_data, :data_map
    end
  end
end
