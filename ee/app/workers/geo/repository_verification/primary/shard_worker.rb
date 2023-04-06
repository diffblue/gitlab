# frozen_string_literal: true

module Geo
  module RepositoryVerification
    module Primary
      class ShardWorker < Geo::Scheduler::Primary::SchedulerWorker # rubocop:disable Scalability/IdempotentWorker
        loggable_arguments 0

        attr_accessor :shard_name

        def perform(shard_name)
          @shard_name = shard_name

          return unless Gitlab::ShardHealthCache.healthy_shard?(shard_name)

          super()
        end

        # We need a custom key here since we are running one worker per shard
        def lease_key
          @lease_key ||= "#{self.class.name.underscore}:shard:#{shard_name}"
        end

        private

        def skip_cache_key
          "#{self.class.name.underscore}:shard:#{shard_name}:skip"
        end

        def worker_metadata
          { shard_name: shard_name }
        end

        def max_capacity
          Gitlab::Geo.verification_max_capacity_per_replicator_class
        end

        def schedule_job(project_id)
          job_id = Geo::RepositoryVerification::Primary::SingleWorker.with_status.perform_async(project_id)

          { id: project_id, job_id: job_id } if job_id
        end

        def finder
          @finder ||= Geo::RepositoryVerificationFinder.new(shard_name: shard_name)
        end

        def load_pending_resources
          resources = find_never_verified_project_ids(batch_size: db_retrieve_batch_size)
          remaining_capacity = db_retrieve_batch_size - resources.size
          return resources if remaining_capacity == 0

          resources += find_recently_updated_project_ids(batch_size: remaining_capacity)
          remaining_capacity = db_retrieve_batch_size - resources.size
          return resources if remaining_capacity == 0

          resources + find_project_ids_to_reverify(batch_size: remaining_capacity)
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def find_never_verified_project_ids(batch_size:)
          finder.find_never_verified_projects(batch_size: batch_size).pluck(:id)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # rubocop: disable CodeReuse/ActiveRecord
        def find_recently_updated_project_ids(batch_size:)
          finder.find_recently_updated_projects(batch_size: batch_size).pluck(:id)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def find_project_ids_to_reverify(batch_size:)
          failed_project_ids = find_failed_project_ids(batch_size: batch_size)
          reverifiable_project_ids = find_reverifiable_projects_ids(batch_size: batch_size)

          take_batch(failed_project_ids, reverifiable_project_ids, batch_size: batch_size)
        end

        def find_failed_project_ids(batch_size:)
          repositories_ids = find_failed_repositories_ids(batch_size: batch_size)
          wiki_ids = find_failed_wiki_ids(batch_size: batch_size)

          take_batch(repositories_ids, wiki_ids, batch_size: batch_size)
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def find_failed_repositories_ids(batch_size:)
          finder.find_failed_repositories(batch_size: batch_size).pluck(:id)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # rubocop: disable CodeReuse/ActiveRecord
        def find_failed_wiki_ids(batch_size:)
          return [] if ::Geo::ProjectWikiRepositoryReplicator.enabled?

          finder.find_failed_wikis(batch_size: batch_size).pluck(:id)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # rubocop: disable CodeReuse/ActiveRecord
        def find_reverifiable_projects_ids(batch_size:)
          return [] unless reverification_enabled?

          jitter   = (minimum_reverification_interval.seconds * rand(15)) / 100
          interval = minimum_reverification_interval.ago + jitter.seconds

          repository_ids = finder.find_reverifiable_repositories(interval: interval, batch_size: batch_size).pluck(:id)
          wiki_ids = find_reverifiable_wikis(interval: interval, batch_size: batch_size)

          take_batch(repository_ids, wiki_ids, batch_size: batch_size)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # rubocop: disable CodeReuse/ActiveRecord
        def find_reverifiable_wikis(interval:, batch_size:)
          return [] if ::Geo::ProjectWikiRepositoryReplicator.enabled?

          finder.find_reverifiable_wikis(interval: interval, batch_size: batch_size).pluck(:id)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def minimum_reverification_interval
          ::Gitlab::Geo.current_node.minimum_reverification_interval.days
        end

        def reverification_enabled?
          ::Feature.enabled?(:geo_repository_reverification)
        end
      end
    end
  end
end
