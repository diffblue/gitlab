# frozen_string_literal: true

class ElasticWikiIndexerWorker
  MAX_JOBS_PER_HOUR = 3600
  include ApplicationWorker

  data_consistency :delayed
  prepend Elastic::IndexingControl
  include Gitlab::ExclusiveLeaseHelpers

  feature_category :global_search
  urgency :throttled
  idempotent!
  loggable_arguments 1, 2

  LOCK_RETRIES = 2
  LOCK_SLEEP_SEC = 1

  # Performs the wiki indexation
  # container_id - The ID of the container(project/group) to index
  # container_type - The class of the container(project/group) to index
  # The indexation will cover all commits within INDEXED_SHA..HEAD
  def perform(container_id, container_type, options = {})
    if container_id.nil? || container_type.nil?
      logger.error(message: 'container_id or container_type can not be nil', container_id: container_id,
        container_type: container_type)
      return true
    end

    container_class = container_type.safe_constantize
    unless container_class == Project || container_class == Group
      logger.error(message: 'ElasticWikiIndexerWorker only accepts Project and Group',
        container_id: container_id, container_type: container_type)
      return true
    end

    return true unless Gitlab::CurrentSettings.elasticsearch_indexing?

    container = container_class.find(container_id)
    unless container.use_elasticsearch?
      cleanup_container_elastic_documents(container_id, container_type)
      return true
    end

    options = options.with_indifferent_access

    force = !!options[:force]
    search_indexing_duration_s = Benchmark.realtime do
      @ret = in_lock("#{self.class.name}/#{container_type}/#{container_id}",
        ttl: (Gitlab::Elastic::Indexer::TIMEOUT + 1.minute), retries: LOCK_RETRIES, sleep_sec: LOCK_SLEEP_SEC) do
        Gitlab::Elastic::Indexer.new(container, wiki: true, force: force).run
      end
    end

    # If the indexer was locked (return = nil),
    # or the container no longer exists in the database (return = false)
    # we do not want to log anything
    if @ret
      case container_type
      when 'Project'
        project_id = container_id
        group_id = container.group&.id
      when 'Group'
        group_id = container_id
      end
      logger.info(
        project_id: project_id,
        group_id: group_id,
        wiki: true,
        search_indexing_duration_s: search_indexing_duration_s,
        jid: jid
      )
      Gitlab::Metrics::GlobalSearchIndexingSlis.record_apdex(elapsed: search_indexing_duration_s, document_type: 'Wiki')
    end

    @ret
  rescue ActiveRecord::RecordNotFound
    logger.warn(message: 'Container record not found', container_type: container_type, container_id: container_id)
    cleanup_container_elastic_documents(container_id, container_type)
    true
  end

  private

  def cleanup_container_elastic_documents(container_id, container_type)
    if container_type == 'Project'
      ElasticDeleteProjectWorker.perform_async(container_id, es_id(container_id, container_type))
    else
      Search::Wiki::ElasticDeleteGroupWikiWorker.perform_async(container_id)
    end
  end

  def es_id(container_id, container_type)
    Gitlab::Elastic::Helper.build_es_id(es_type: container_type.safe_constantize&.es_type, target_id: container_id)
  end
end
