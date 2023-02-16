# frozen_string_literal: true

class ElasticCommitIndexerWorker
  include ApplicationWorker

  data_consistency :always
  prepend Elastic::IndexingControl
  include Gitlab::ExclusiveLeaseHelpers

  feature_category :global_search
  sidekiq_options retry: 2
  urgency :throttled
  idempotent!
  loggable_arguments 1, 2

  # Performs the commits and blobs indexation
  #
  # project_id - The ID of the project to index
  # wiki - Treat this project as a Wiki
  # options - Options hash { force: bool } forces to reindex the repository
  #
  # The indexation will cover all commits within INDEXED_SHA..HEAD
  def perform(project_id, wiki = false, options = {})
    return true unless Gitlab::CurrentSettings.elasticsearch_indexing?

    @project = Project.find(project_id)
    return true unless @project.use_elasticsearch?

    force = !!options['force']
    search_indexing_duration_s = Benchmark.realtime do
      @ret = in_lock("#{self.class.name}/#{project_id}/#{wiki}", ttl: (Gitlab::Elastic::Indexer.timeout + 1.minute), retries: 0) do
        Gitlab::Elastic::Indexer.new(@project, wiki: wiki, force: force).run
      end
    end

    if @ret
      # If the indexer was locked (return = nil),
      # or the project no longer exists in the database (return = false)
      # we do not want to log anything
      logger.info(
        project_id: project_id,
        wiki: wiki,
        search_indexing_duration_s: search_indexing_duration_s,
        jid: jid
      )

      document_type = wiki ? 'Wiki' : 'Code'
      Gitlab::Metrics::GlobalSearchIndexingSlis.record_apdex(elapsed: search_indexing_duration_s, document_type: document_type)

      if force && !wiki && @project.statistics
        log_extra_metadata_on_done(:commit_count, @project.statistics.commit_count)
        log_extra_metadata_on_done(:repository_size, @project.statistics.repository_size)
      end
    end

    @ret
  end
end
