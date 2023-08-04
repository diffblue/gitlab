# frozen_string_literal: true

module Search
  class ElasticGroupAssociationDeletionWorker
    include ApplicationWorker
    prepend ::Elastic::IndexingControl

    MAX_JOBS_PER_HOUR = 3600

    sidekiq_options retry: 3
    data_consistency :delayed
    feature_category :global_search
    urgency :throttled
    idempotent!

    def perform(group_id, ancestor_id)
      remove_epics(group_id, ancestor_id) if Epic.elasticsearch_available?
    end

    private

    def remove_epics(group_id, ancestor_id)
      Gitlab::Search::Client.new.delete_by_query(
        {
          index: ::Elastic::Latest::EpicConfig.index_name,
          routing: "group_#{ancestor_id}",
          conflicts: 'proceed',
          timeout: "10m",
          body: {
            query: {
              bool: {
                filter: {
                  term: {
                    group_id: group_id
                  }
                }
              }
            }
          }
        }
      )
    end
  end
end
