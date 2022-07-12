# frozen_string_literal: true

module Ci
  module Minutes
    class RefreshCachedDataService
      BATCH_SIZE = 1_000

      def initialize(root_namespace)
        @root_namespace = root_namespace
      end

      def execute
        return unless @root_namespace

        reset_ci_minutes_cache!
        update_pending_builds!
      rescue StandardError => e
        ::Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
          e,
          root_namespace_id: @root_namespace.id
        )
      end

      def reset_ci_minutes_cache!
        ::Gitlab::Ci::Minutes::CachedQuota.new(@root_namespace).expire!
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def update_pending_builds!
        minutes_exceeded = @root_namespace.ci_minutes_usage.minutes_used_up?
        all_namespace_ids = @root_namespace.self_and_descendant_ids.ids

        all_namespace_ids.in_groups_of(BATCH_SIZE, minutes_exceeded) do |namespace_ids|
          ::Ci::PendingBuild.where(namespace: namespace_ids).update_all(minutes_exceeded: minutes_exceeded)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
