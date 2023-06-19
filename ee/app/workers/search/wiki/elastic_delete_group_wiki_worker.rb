# frozen_string_literal: true

# Support bulk delete
module Search
  module Wiki
    class ElasticDeleteGroupWikiWorker
      MAX_JOBS_PER_HOUR = 3600

      include ApplicationWorker

      data_consistency :delayed
      prepend Elastic::IndexingControl

      feature_category :global_search
      urgency :throttled
      idempotent!

      def perform(group_id)
        remove_group_wiki_documents(group_id)
      end

      private

      def remove_group_wiki_documents(group_id)
        Gitlab::Elastic::Helper.default.client.delete_by_query(
          {
            index: Elastic::Latest::WikiConfig.index_name,
            routing: "group_#{group_id}",
            conflicts: 'proceed',
            body: {
              query: {
                bool: {
                  filter: {
                    term: {
                      rid: "wiki_group_#{group_id}"
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
end
