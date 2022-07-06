# frozen_string_literal: true

module Security
  module Ingestion
    module Tasks
      # UPSERTs the identifiers for the given findings and
      # sets the identifier IDs for each `finding_map`.
      class IngestIdentifiers < AbstractTask
        include Gitlab::Ingestion::BulkInsertableTask

        self.model = Vulnerabilities::Identifier
        self.unique_by = %i[project_id fingerprint]
        self.uses = %i[fingerprint id]

        private

        delegate :project, to: :pipeline, private: true

        def after_ingest
          return_data.to_h.then do |fingerprint_to_id_map|
            finding_maps.each { |finding_map| finding_map.set_identifier_ids_by(fingerprint_to_id_map) }
          end
        end

        # Important Note:
        #   Sorting identifiers is important to prevent having deadlock
        #   errors which can happen if other threads try to import the same
        #   identifiers in different order.
        def attributes
          report_identifiers.map { |identifier| identifier.to_hash.merge!(project_id: project.id) }
                            .sort_by { |identifier_data| identifier_data[:fingerprint] }
        end

        def report_identifiers
          @report_identifiers ||= finding_maps.flat_map(&:identifiers).uniq(&:fingerprint)
        end
      end
    end
  end
end
