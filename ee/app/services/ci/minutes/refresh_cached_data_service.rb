# frozen_string_literal: true

module Ci
  module Minutes
    class RefreshCachedDataService
      def initialize(root_namespace)
        @root_namespace = root_namespace
      end

      def execute
        return unless @root_namespace

        reset_ci_minutes_cache!
        update_pending_builds!
      rescue StandardError => e
        ::Gitlab::ErrorTracking.track_exception(
          e,
          root_namespace_id: @root_namespace.id
        )
      end

      def reset_ci_minutes_cache!
        ::Gitlab::Ci::Minutes::CachedQuota.new(@root_namespace).expire!
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def update_pending_builds!
        return unless ::Feature.enabled?(:ci_pending_builds_maintain_ci_minutes_data, @root_namespace, type: :development, default_enabled: :yaml)

        minutes_exceeded = @root_namespace.ci_minutes_quota.minutes_used_up?
        all_namespaces = @root_namespace.self_and_descendant_ids

        ::Ci::PendingBuild.where(namespace: all_namespaces).update_all(minutes_exceeded: minutes_exceeded)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
