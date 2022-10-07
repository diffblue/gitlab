# frozen_string_literal: true

module Security
  module Ingestion
    module Tasks
      class IngestVulnerabilities < AbstractTask
        def execute
          create_new_vulnerabilities
          update_existing_vulnerabilities
          mark_resolved_vulnerabilities_as_detected

          finding_maps
        end

        private

        def create_new_vulnerabilities
          IngestVulnerabilities::Create.new(pipeline, partitioned_maps.first).execute
        end

        def update_existing_vulnerabilities
          IngestVulnerabilities::Update.new(pipeline, partitioned_maps.second).execute
        end

        def mark_resolved_vulnerabilities_as_detected
          IngestVulnerabilities::MarkResolvedAsDetected.execute(pipeline, partitioned_maps.second)
        end

        def partitioned_maps
          @partitioned_maps ||= finding_maps.partition { |finding_map| finding_map.vulnerability_id.nil? }
        end
      end
    end
  end
end
