# frozen_string_literal: true

module PackageMetadata
  module Ingestion
    module Advisory
      class IngestionService
        def self.execute(import_data)
          new(import_data).execute
        end

        def initialize(import_data)
          @import_data = import_data
          @advisory_map = {}
        end

        def execute
          ApplicationRecord.transaction do
            upsert_advisory_data
            upsert_affected_package_data
          end
          publish!
        end

        private

        def upsert_advisory_data
          @advisory_map = AdvisoryIngestionTask.execute(import_data)
        end

        def upsert_affected_package_data
          AffectedPackageIngestionTask.execute(import_data, advisory_map)
        end

        def publish!
          return unless Feature.enabled?(:dependency_scanning_on_advisory_ingestion)

          advisory_map.each_value do |advisory_id|
            Gitlab::EventStore.publish(
              PackageMetadata::IngestedAdvisoryEvent.new(data: { advisory_id: advisory_id }))
          end
        end

        attr_reader :import_data, :advisory_map
      end
    end
  end
end
