# frozen_string_literal: true

module Sbom
  module Ingestion
    module Tasks
      class IngestSources < Base
        def execute
          # For now, there is only one source per report,
          # so all occurrence maps in the batch will use the same one.
          # This is likely to change in the future, so the interface
          # allows for multiple sources.
          return unless report_source.present?

          occurrence_maps.each do |occurrence_map|
            occurrence_map.source_id = source.id
          end
        end

        private

        delegate :source_type, :data, to: :report_source, private: true

        def source
          @source ||= find_or_create_source
        end

        def find_or_create_source
          # rubocop:disable CodeReuse/ActiveRecord
          ::Sbom::Source.find_or_create_by(
            source_type: source_type,
            source: data
          )
          # rubocop:enable CodeReuse/ActiveRecord
        end

        def report_source
          @report_source ||= occurrence_maps.first.report_source
        end
      end
    end
  end
end
