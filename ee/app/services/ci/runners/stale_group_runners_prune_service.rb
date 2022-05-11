# frozen_string_literal: true

module Ci
  module Runners
    class StaleGroupRunnersPruneService
      include BaseServiceUtility

      GROUP_BATCH_SIZE = 1_000

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
          total_count += stale_runners(namespace_id_batch.to_a).delete_all
        end

        total_count
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
