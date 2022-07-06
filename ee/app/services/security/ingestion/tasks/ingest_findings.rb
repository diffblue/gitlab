# frozen_string_literal: true

module Security
  module Ingestion
    module Tasks
      class IngestFindings < AbstractTask
        include Gitlab::Ingestion::BulkInsertableTask

        self.model = Vulnerabilities::Finding
        self.unique_by = :uuid
        self.uses = %i[id vulnerability_id].freeze

        private

        delegate :project, to: :pipeline, private: true

        def after_ingest
          return_data.each_with_index do |(finding_id, vulnerability_id), index|
            finding_map = finding_maps[index]

            finding_map.finding_id = finding_id
            finding_map.vulnerability_id = vulnerability_id
          end
        end

        def attributes
          finding_maps.map { |finding_map| finding_map.to_hash.merge(project_id: project.id) }
        end
      end
    end
  end
end
