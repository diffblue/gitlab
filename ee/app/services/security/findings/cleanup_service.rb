# frozen_string_literal: true

module Security
  module Findings
    class CleanupService
      MAX_STALE_SCANS_SIZE = 50_000
      SCAN_BATCH_SIZE = 100
      BATCH_DELETE_SIZE = 100

      class << self
        def delete_stale_records
          Security::Scan.stale.limit(MAX_STALE_SCANS_SIZE).then(&method(:execute))
        end

        def delete_by_build_ids(build_ids)
          Security::Scan.by_build_ids(build_ids).then(&method(:execute))
        end

        def execute(security_scans)
          new(security_scans).execute
        end
      end

      def initialize(security_scans)
        @security_scans = security_scans
      end

      def execute
        security_scans.in_batches(of: SCAN_BATCH_SIZE, &method(:purge)) # rubocop:disable Cop/InBatches (`each_batch` does not let us set a global limit of records to be batched)
      end

      private

      attr_reader :security_scans

      def purge(scan_batch)
        delete_findings_for(scan_batch.where_values_hash['id'])

        scan_batch.unscope(where: :build_id).update_all(status: :purged) # rubocop:disable CodeReuse/ActiveRecord unlikely that a `unscope where build_id` scope would be used elsewhere
      end

      def delete_findings_for(scan_batch)
        findings_relation = Security::Finding.by_scan(scan_batch).limit(BATCH_DELETE_SIZE)

        loop do
          break if findings_relation.delete_all < BATCH_DELETE_SIZE
        end
      end
    end
  end
end
