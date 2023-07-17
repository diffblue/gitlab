# frozen_string_literal: true

module PackageMetadata
  module Ingestion
    module Advisory
      class AdvisoryIngestionTask
        def initialize(import_data)
          @import_data = import_data
          @advisory_map = {}
        end

        def self.execute(import_data)
          new(import_data).execute
        end

        def execute
          results = PackageMetadata::Advisory.bulk_upsert!(valid_advisories, unique_by: %w[advisory_xid source_xid],
            returns: %w[advisory_xid id])

          advisory_map.merge!(results.to_h)
        end

        private

        attr_reader :import_data, :advisory_map

        # validate checks the list of provided advisory models and returns
        # only those which are valid and logs the invalid packages as an error
        def valid_advisories
          advisories.map do |advisory|
            if advisory.invalid?
              Gitlab::AppJsonLogger.error(class: self.class.name,
                message: "invalid advisory",
                source_xid: advisory.source_xid,
                advisory_xid: advisory.advisory_xid,
                errors: advisory.errors.to_hash)
              next
            end

            advisory
          end.reject(&:blank?)
        end

        def advisories
          import_data.map do |data_object|
            PackageMetadata::Advisory.new(
              advisory_xid: data_object.advisory_xid,
              source_xid: data_object.source_xid,
              published_date: data_object.published_date,
              title: data_object.title,
              description: data_object.description,
              cvss_v2: data_object.cvss_v2,
              cvss_v3: data_object.cvss_v3,
              identifiers: data_object.identifiers,
              urls: data_object.urls,
              created_at: now,
              updated_at: now
            )
          end
        end

        def now
          @now ||= Time.zone.now
        end
      end
    end
  end
end
