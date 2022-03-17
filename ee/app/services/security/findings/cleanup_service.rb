# frozen_string_literal: true

module Security
  module Findings
    class CleanupService
      MAX_STALE_SCANS_SIZE = 50_000
      BATCH_DELETE_SIZE = 10_000

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
        security_scans.in_batches(&method(:purge)) # rubocop:disable Cop/InBatches (`each_batch` does not let us set a global limit of records to be batched)
      end

      private

      attr_reader :security_scans

      def purge(scan_batch)
        delete_findings_for(scan_batch)

        scan_batch.update_all(status: :purged)
      end

      def delete_findings_for(scan_batch)
        Security::Finding.by_scan(scan_batch).each_batch(of: BATCH_DELETE_SIZE) do |finding_batch|
          finding_batch.delete_all
        end
      end
    end
  end
end
