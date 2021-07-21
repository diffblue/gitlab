# frozen_string_literal: true

class ElasticNamespaceRolloutWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  feature_category :global_search
  sidekiq_options retry: 2
  loggable_arguments 0, 2

  ROLLOUT = 'rollout'
  ROLLBACK = 'rollback'

  # @param plan [String] which plan the rollout is scoped to
  # @param percentage [Integer]
  # @param mode [ROLLOUT, ROLLBACK] determine whether to rollout or rollback
  def perform(plan, percentage, mode)
    total_with_plan = GitlabSubscription.with_hosted_plan(plan).count

    expected_count = total_with_plan * (percentage / 100.0)

    current_count = ElasticsearchIndexedNamespace
      .namespace_in(GitlabSubscription.with_hosted_plan(plan).select(:namespace_id))
      .count

    case mode
    when ROLLOUT
      rollout(plan, expected_count, current_count)
    when ROLLBACK
      rollback(plan, expected_count, current_count)
    end
  end

  private

  def rollout(plan, expected_count, current_count)
    required_count_changes = [expected_count - current_count, 0].max

    logger.info(message: 'rollout_elasticsearch_indexed_namespaces', changes: required_count_changes, expected_count: expected_count, current_count: current_count, plan: plan)

    if required_count_changes > 0
      ElasticsearchIndexedNamespace.index_first_n_namespaces_of_plan(plan, required_count_changes)
    end
  end

  def rollback(plan, expected_count, current_count)
    required_count_changes = [current_count - expected_count, 0].max

    logger.info(message: 'rollback_elasticsearch_indexed_namespaces', changes: required_count_changes, expected_count: expected_count, current_count: current_count, plan: plan)

    if required_count_changes > 0
      ElasticsearchIndexedNamespace.unindex_last_n_namespaces_of_plan(plan, required_count_changes)
    end
  end

  def logger
    @logger ||= ::Gitlab::Elasticsearch::Logger.build
  end
end
