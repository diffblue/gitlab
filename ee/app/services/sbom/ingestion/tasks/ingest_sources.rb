# frozen_string_literal: true

module Sbom
  module Ingestion
    module Tasks
      class IngestSources < Base
        # For now, there is only one source per report,
        # so all occurrence maps in the batch will use the same one.
        # This is likely to change in the future, so the interface
        # allows for multiple sources.
        include Gitlab::Ingestion::BulkInsertableTask

        self.model = Sbom::Source
        self.uses = :id
        self.unique_by = %i[source_type source].freeze

        private

        delegate :source_type, :data, to: :report_source, private: true

        def after_ingest
          source_id = return_data.first

          return unless source_id

          occurrence_maps.each do |occurrence_map|
            occurrence_map.source_id = source_id
          end
        end

        def attributes
          return [] unless report_source.present?

          [{
            source_type: source_type,
            source: data
          }]
        end

        def report_source
          @report_source ||= occurrence_maps.first&.report_source
        end
      end
    end
  end
end
