# frozen_string_literal: true

# For each project in range,
# indexing the repository, wiki and its nested models
# (e.g. )issues and notes etc.)
# Intended for full site indexing.
class ElasticFullIndexWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 2
  feature_category :global_search

  def perform(start_id, end_id)
    return true unless Gitlab::CurrentSettings.elasticsearch_indexing?

    Project.id_in(start_id..end_id).find_each do |project|
      Elastic::ProcessInitialBookkeepingService.backfill_projects!(project)
    end
  end
end
