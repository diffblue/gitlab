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
  loggable_arguments 1, 2, 3

  # Performs the commits and blobs indexation
  #
  # project_id - The ID of the project to index
  # wiki - Treat this project as a Wiki
  #
  # The indexation will cover all commits within INDEXED_SHA..HEAD
  def perform(project_id, wiki = false)
    return true unless Gitlab::CurrentSettings.elasticsearch_indexing?

    project = Project.find(project_id)
    return true unless project.use_elasticsearch?

    in_lock("#{self.class.name}/#{project_id}/#{wiki}", ttl: (Gitlab::Elastic::Indexer::TIMEOUT + 1.minute), retries: 0) do
      Gitlab::Elastic::Indexer.new(project, wiki: wiki).run
    end
  end
end
