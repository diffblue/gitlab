# frozen_string_literal: true

module EE
  module Git
    module BranchPushService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        enqueue_elasticsearch_indexing
        enqueue_zoekt_indexing
        enqueue_update_external_pull_requests
        enqueue_product_analytics_event_metrics

        super
      end

      private

      def enqueue_product_analytics_event_metrics
        return unless project.product_analytics_enabled?
        return unless default_branch?

        ::ProductAnalytics::PostPushWorker.perform_async(project.id, newrev)
      end

      def enqueue_elasticsearch_indexing
        return unless should_index_commits?

        project.repository.index_commits_and_blobs
      end

      def enqueue_zoekt_indexing
        return false unless ::Feature.enabled?(:index_code_with_zoekt)
        return false unless default_branch?
        return false unless project.use_zoekt?

        project.repository.async_update_zoekt_index
      end

      def enqueue_update_external_pull_requests
        return unless project.mirror?
        return unless params.fetch(:create_pipelines, true)

        UpdateExternalPullRequestsWorker.perform_async(
          project.id,
          current_user.id,
          ref
        )
      end

      def should_index_commits?
        return false unless default_branch?

        project.use_elasticsearch?
      end
    end
  end
end
