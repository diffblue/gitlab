# frozen_string_literal: true

module Issues
  class RescheduleStuckIssueRebalancesWorker
    include ApplicationWorker
    include CronjobQueue

    data_consistency :always

    idempotent!
    urgency :low
    feature_category :issue_tracking
    deduplicate :until_executed, including_scheduled: true

    def perform
      namespace_ids, project_ids = fetch_rebalancing_groups_and_projects

      return if namespace_ids.blank? && project_ids.blank?

      namespaces = Namespace.id_in(namespace_ids)
      projects = Project.id_in(project_ids)

      IssueRebalancingWorker.bulk_perform_async_with_contexts(
        namespaces,
        arguments_proc: -> (namespace) { [nil, nil, namespace.id] },
        context_proc: -> (namespace) { { namespace: namespace } }
      )

      IssueRebalancingWorker.bulk_perform_async_with_contexts(
        projects,
        arguments_proc: -> (project) { [nil, project.id, nil] },
        context_proc: -> (project) { { namespace: project } }
      )
    end

    private

    def fetch_rebalancing_groups_and_projects
      namespace_ids = []
      project_ids = []

      all_rebalancing_containers = Gitlab::Redis::SharedState.with do |redis|
        redis.smembers(Gitlab::Issues::Rebalancing::State::CONCURRENT_RUNNING_REBALANCES_KEY)
      end

      all_rebalancing_containers.each do |string|
        container_type, container_id = string.split('/', 2).map(&:to_i)

        if container_type == Gitlab::Issues::Rebalancing::State::NAMESPACE
          namespace_ids << container_id
        elsif container_type == Gitlab::Issues::Rebalancing::State::PROJECT
          project_ids << container_id
        end
      end

      [namespace_ids, project_ids]
    end
  end
end
