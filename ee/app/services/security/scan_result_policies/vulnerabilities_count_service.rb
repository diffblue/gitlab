# frozen_string_literal: true

module Security
  module ScanResultPolicies
    class VulnerabilitiesCountService
      COUNT_BATCH_SIZE = 50

      def initialize(pipeline:, uuids:, states:, allowed_count:)
        @pipeline = pipeline
        @uuids = uuids
        @states = states
        @allowed_count = allowed_count
      end

      attr_reader :pipeline, :uuids, :states, :allowed_count

      def execute
        result_count = 0
        exceeded_allowed_count = false

        uuids.each_slice(COUNT_BATCH_SIZE) do |uuids_batch|
          result_count += count_vulnerabilities_by_uuid_and_state(uuids_batch)

          if result_count > allowed_count
            exceeded_allowed_count = true
            break
          end
        end

        { count: result_count, exceeded_allowed_count: exceeded_allowed_count }
      end

      private

      def count_vulnerabilities_by_uuid_and_state(uuids_batch)
        pipeline
          .project
          .vulnerability_reads
          .by_uuid(uuids_batch)
          .with_states(states)
          .count
      end
    end
  end
end
