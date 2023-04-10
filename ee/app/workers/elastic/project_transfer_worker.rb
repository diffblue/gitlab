# frozen_string_literal: true

module Elastic
  class ProjectTransferWorker
    include ApplicationWorker

    data_consistency :delayed

    feature_category :global_search
    idempotent!
    urgency :throttled

    def perform(project_id, old_namespace_id, new_namespace_id)
      project = Project.find(project_id)
      should_invalidate_elasticsearch_indexes_cache = should_invalidate_elasticsearch_indexes_cache?(
        old_namespace_id, new_namespace_id
      )

      if should_invalidate_elasticsearch_indexes_cache
        project.invalidate_elasticsearch_indexes_cache!
      end

      if project.maintaining_elasticsearch?
        # If the project is indexed in Elasticsearch, the project and all associated data are queued up for indexing
        # to make sure the namespace_ancestry field gets updated in each document.
        ::Elastic::ProcessInitialBookkeepingService.backfill_projects!(project)
      elsif should_invalidate_elasticsearch_indexes_cache &&
          ::Gitlab::CurrentSettings.elasticsearch_indexing?
        # If the project is no longer indexed and the indexing settings are different between the old and new namespace,
        # the project should no longer exist in the index and will be deleted asynchronously.
        ElasticDeleteProjectWorker.perform_async(project.id, project.es_id)
      end
    end

    private

    def should_invalidate_elasticsearch_indexes_cache?(old_namespace_id, new_namespace_id)
      # When a project is moved to a new namespace, invalidate the Elasticsearch cache if
      # Elasticsearch limit indexing is enabled and the indexing settings are different between the two namespaces.
      return false unless ::Gitlab::CurrentSettings.elasticsearch_limit_indexing?

      old_namespace = Namespace.find_by(id: old_namespace_id) # rubocop: disable CodeReuse/ActiveRecord
      new_namespace = Namespace.find_by(id: new_namespace_id) # rubocop: disable CodeReuse/ActiveRecord

      return ::Gitlab::CurrentSettings.elasticsearch_limit_indexing? unless old_namespace && new_namespace

      old_namespace.use_elasticsearch? != new_namespace.use_elasticsearch?
    end
  end
end
