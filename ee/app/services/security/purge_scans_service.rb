# frozen_string_literal: true

module Security
  class PurgeScansService
    MAX_STALE_SCANS_SIZE = 50_000
    SCAN_BATCH_SIZE = 100

    class << self
      def purge_stale_records
        Security::Scan.stale.limit(MAX_STALE_SCANS_SIZE).then { |relation| execute(relation) }
      end

      def purge_by_build_ids(build_ids)
        Security::Scan.by_build_ids(build_ids).then { |relation| execute(relation) }
      end

      def execute(security_scans)
        new(security_scans).execute
      end
    end

    def initialize(security_scans)
      @security_scans = security_scans
    end

    def execute
      security_scans.in_batches(of: SCAN_BATCH_SIZE) { |batch| purge(batch) } # rubocop:disable Cop/InBatches (`each_batch` does not let us set a global limit of records to be batched)
    end

    private

    attr_reader :security_scans

    def purge(scan_batch)
      scan_batch.unscope(where: :build_id).update_all(status: :purged) # rubocop:disable CodeReuse/ActiveRecord unlikely that a `unscope where build_id` scope would be used elsewhere
    end
  end
end
