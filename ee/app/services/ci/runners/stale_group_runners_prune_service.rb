# frozen_string_literal: true

module Ci
  module Runners
    class StaleGroupRunnersPruneService
      include BaseServiceUtility

      GROUP_BATCH_SIZE = 1_000
      BATCH_SIZE = 5_000
      PAUSE_SECONDS = 2

      def perform(groups)
        total_pruned = delete_stale_group_runners(groups)

        success({ total_pruned: total_pruned })
      end

      private

      def stale_runners(group_batch)
        Ci::Runner.belonging_to_group(group_batch).stale
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def delete_stale_group_runners(groups)
        return 0 unless groups&.any?

        total_count = 0

        groups.each_batch(of: GROUP_BATCH_SIZE, order_hint: :id) do |group_batch|
          loop do
            count = delete_stale_group_runners_in_batches(group_batch.ids)
            total_count += count
            break if count < BATCH_SIZE

            sleep PAUSE_SECONDS
          end
        end

        total_count
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def delete_stale_group_runners_in_batches(group_batch)
        # We can't use EachBatch because that does an ORDER BY id, which can
        # easily time out. We don't actually care about ordering when
        # we are deleting these rows.
        stale_runners(group_batch).limit(BATCH_SIZE).delete_all
      end
    end
  end
end
