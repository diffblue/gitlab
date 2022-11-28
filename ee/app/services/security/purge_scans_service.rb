# frozen_string_literal: true

module Security
  class PurgeScansService
    MAX_STALE_SCANS_SIZE = 50_000
    SCAN_BATCH_SIZE = 100

    class << self
      def purge_stale_records
        Security::Scan.stale.ordered_by_created_at_and_id.then { |relation| execute(relation) }
      end

      def purge_by_build_ids(build_ids)
        Security::Scan.by_build_ids(build_ids).then { |relation| execute(relation) }
      end

      def execute(security_scans)
        new(security_scans).execute
      end
    end

    def initialize(security_scans)
      @iterator = Gitlab::Pagination::Keyset::Iterator.new(scope: security_scans)
      @updated_count = 0
    end

    def execute
      iterator.each_batch(of: SCAN_BATCH_SIZE) do |batch|
        @updated_count += purge(batch)

        break if @updated_count >= MAX_STALE_SCANS_SIZE
      end
    end

    private

    attr_reader :iterator

    def purge(scan_batch)
      scan_batch.update_all(status: :purged)
    end
  end
end
