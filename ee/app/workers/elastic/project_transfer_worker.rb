# frozen_string_literal: true

module Elastic
  class ProjectTransferWorker
    include ApplicationWorker

    data_consistency :delayed

    feature_category :global_search
    idempotent!
    urgency :throttled

    def perform(project_id, old_namespace_id, new_namespace_id)
      old_namespace = Namespace.find(old_namespace_id)
      new_namespace = Namespace.find(new_namespace_id)
      project = Project.find(project_id)

      # When a project is moved to a new namespace, invalidate the Elasticsearch cache if
      # Elasticsearch limit indexing is enabled and the indexing settings are different between the two namespaces.
      should_invalidate_elasticsearch_indexes_cache = ::Gitlab::CurrentSettings.elasticsearch_limit_indexing? &&
        old_namespace.use_elasticsearch? != new_namespace.use_elasticsearch?
      if should_invalidate_elasticsearch_indexes_cache
        project.invalidate_elasticsearch_indexes_cache!
      end

      if project.maintaining_elasticsearch?
        # If the project is indexed in Elasticsearch, the project and all associated data are queued up for indexing
        # to make sure the namespace_ancestry field gets updated in each document.
        ::Elastic::ProcessInitialBookkeepingService.backfill_projects!(project)
      else
        # If the project is no longer indexed and the indexing settings are different between the old and new namespace,
        # the project should no longer exist in the index and will be deleted asynchronously.
        ElasticDeleteProjectWorker.perform_async(project.id, project.es_id) if
          should_invalidate_elasticsearch_indexes_cache &&
          ::Gitlab::CurrentSettings.elasticsearch_indexing?
      end
    end
  end
end
