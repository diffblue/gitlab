# frozen_string_literal: true

module Ci
  module Runners
    class StaleGroupRunnersPruneService
      GROUP_BATCH_SIZE = 1_000

      def execute(namespace_ids)
        total_pruned = delete_stale_group_runners(namespace_ids)

        ServiceResponse.success(payload: { total_pruned: total_pruned })
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
          selected_namespaces = Namespace.find(namespace_id_batch.ids)

          if ::Gitlab::CurrentSettings.should_check_namespace_plan?
            ::Gitlab::GroupPlansPreloader.new.preload(selected_namespaces)
          end

          selected_namespace_ids = selected_namespaces
            .filter { |namespace| namespace.licensed_feature_available?(:stale_runner_cleanup_for_namespace) }
            .map(&:id)

          total_count += stale_runners(selected_namespace_ids).delete_all
        end

        total_count
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
