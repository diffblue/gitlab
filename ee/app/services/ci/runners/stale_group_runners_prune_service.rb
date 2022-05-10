# frozen_string_literal: true

module Ci
  module Runners
    class StaleGroupRunnersPruneService
      include BaseServiceUtility

      GROUP_BATCH_SIZE = 1_000
      BATCH_SIZE = 2_000
      PAUSE_SECONDS = 2

      def perform(namespace_ids)
        total_pruned = delete_stale_group_runners(namespace_ids)

        success({ total_pruned: total_pruned })
      end

      private

      def stale_runners(namespace_id_batch)
        Ci::Runner.belonging_to_group(namespace_id_batch).stale
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def delete_stale_group_runners(namespace_ids)
        return 0 if namespace_ids.empty?

        total_count = 0

        namespace_ids.each_batch(of: GROUP_BATCH_SIZE) do |namespace_id_batch|
          count = delete_stale_group_runners_in_batches(namespace_id_batch.to_a)
          total_count += count
        end

        total_count
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def delete_stale_group_runners_in_batches(namespace_id_batch)
        # Prune stale runners in small batches of `BATCH_SIZE` in order to reduce pressure on the database and
        # to allow it to perform any cleanup required.

        count = 0
        stale_runners(namespace_id_batch).each_batch(of: BATCH_SIZE) do |runner_batch|
          count += runner_batch.delete_all
          sleep PAUSE_SECONDS
        end

        count
      end
    end
  end
end
