# frozen_string_literal: true

module Security
  module Ingestion
    module Tasks
      class IngestFindingSignatures < AbstractTask
        include Gitlab::Ingestion::BulkInsertableTask

        self.model = Vulnerabilities::FindingSignature
        self.unique_by = %i[finding_id algorithm_type signature_sha].freeze

        private

        def attributes
          finding_maps.flat_map { |finding_map| attributes_for(finding_map) }
        end

        def attributes_for(finding_map)
          finding_map.report_finding.signatures.map do |signature|
            {
              finding_id: finding_map.finding_id,
              algorithm_type: signature.algorithm_type,
              signature_sha: signature.signature_sha
            }
          end
        end
      end
    end
  end
end
