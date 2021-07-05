# frozen_string_literal: true

class ElasticNamespaceIndexerWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  feature_category :global_search
  sidekiq_options retry: 2
  loggable_arguments 1

  def perform(namespace_id, operation)
    return true unless Gitlab::CurrentSettings.elasticsearch_indexing?
    return true unless Gitlab::CurrentSettings.elasticsearch_limit_indexing?

    namespace = Namespace.find(namespace_id)

    case operation.to_s
    when /index/
      index_projects(namespace)
    when /delete/
      delete_from_index(namespace)
    end
  end

  private

  def index_projects(namespace)
    namespace.all_projects.find_in_batches do |batch|
      ::Elastic::ProcessInitialBookkeepingService.backfill_projects!(*batch)
    end
  end

  def delete_from_index(namespace)
    namespace.all_projects.find_in_batches do |batch|
      args = batch.map { |project| [project.id, project.es_id] }
      ElasticDeleteProjectWorker.bulk_perform_async(args) # rubocop:disable Scalability/BulkPerformWithContext
    end
  end
end
