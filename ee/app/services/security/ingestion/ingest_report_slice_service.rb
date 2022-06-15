# frozen_string_literal: true

module Security
  module Ingestion
    # Base class to organize the chain of responsibilities
    # for the report slice.
    #
    # Returns the ingested vulnerability IDs.
    class IngestReportSliceService
      TASKS = %i[
        IngestIdentifiers
        IngestFindings
        IngestVulnerabilities
        AttachFindingsToVulnerabilities
        IngestFindingPipelines
        IngestFindingIdentifiers
        IngestFindingLinks
        IngestFindingSignatures
        IngestFindingEvidence
        IngestVulnerabilityFlags
        IngestIssueLinks
        IngestVulnerabilityStatistics
        IngestRemediations
        HooksExecution
      ].freeze

      def self.execute(pipeline, finding_maps)
        new(pipeline, finding_maps).execute
      end

      def initialize(pipeline, finding_maps)
        @pipeline = pipeline
        @finding_maps = finding_maps
      end

      def execute
        Security::Ingestion::Tasks::UpdateVulnerabilityUuids.execute(@pipeline, @finding_maps)

        ApplicationRecord.transaction do
          TASKS.each { |task| execute_task(task) }
        end

        @finding_maps.map(&:vulnerability_id)
      end

      private

      def execute_task(task)
        Tasks.const_get(task, false).execute(@pipeline, @finding_maps)
      end
    end
  end
end
