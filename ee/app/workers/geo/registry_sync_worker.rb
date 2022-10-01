# frozen_string_literal: true

module Geo
  class RegistrySyncWorker < Geo::Scheduler::Secondary::SchedulerWorker
    # This worker does not perform work scoped to a context
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    idempotent!

    private

    # We use inexpensive queries now so we don't need a backoff time
    #
    # Overrides Geo::Scheduler::SchedulerWorker#should_apply_backoff?
    def should_apply_backoff?
      false
    end

    def max_capacity
      # All blob types are handled by this worker.
      #
      # Note that Group wiki Git repos and Snippet repos are also handled by
      # this worker at the moment.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/372488
      capacity = current_node.files_max_capacity

      # Transition-period-solution, see
      # https://gitlab.com/gitlab-org/gitlab/-/issues/372444#note_1087132645c
      if Feature.enabled?(:geo_container_repository_replication)
        capacity += current_node.container_repositories_max_capacity
      end

      capacity
    end

    def schedule_job(replicable_name, model_record_id)
      job_id = ::Geo::EventWorker.with_status.perform_async(replicable_name, :created, model_record_id: model_record_id)

      { model_record_id: model_record_id, replicable_name: replicable_name, job_id: job_id } if job_id
    end

    # Pools for new resources to be transferred
    #
    # @return [Array] resources to be transferred
    def load_pending_resources
      resources = find_jobs_never_attempted_sync(batch_size: db_retrieve_batch_size)
      remaining_capacity = db_retrieve_batch_size - resources.count

      if remaining_capacity == 0
        resources
      else
        resources + find_jobs_needs_sync_again(batch_size: remaining_capacity)
      end
    end

    # Get a batch of resources that never have an attempt to sync, taking
    # equal parts from each resource.
    #
    # @return [Array] job arguments of resources that never have an attempt to sync
    def find_jobs_never_attempted_sync(batch_size:)
      jobs = replicator_classes.reduce([]) do |jobs, replicator_class|
        except_ids = scheduled_replicable_ids(replicator_class.replicable_name)

        jobs << replicator_class
                  .find_registries_never_attempted_sync(batch_size: batch_size, except_ids: except_ids)
                  .map { |registry| [replicator_class.replicable_name, registry.model_record_id] }
      end

      take_batch(*jobs, batch_size: batch_size)
    end

    # Get a batch of failed and synced-but-missing-on-primary resources, taking
    # equal parts from each resource.
    #
    # @return [Array] job arguments of low priority resources
    def find_jobs_needs_sync_again(batch_size:)
      jobs = replicator_classes.reduce([]) do |jobs, replicator_class|
        except_ids = scheduled_replicable_ids(replicator_class.replicable_name)

        jobs << replicator_class
                  .find_registries_needs_sync_again(batch_size: batch_size, except_ids: except_ids)
                  .map { |registry| [replicator_class.replicable_name, registry.model_record_id] }
      end

      take_batch(*jobs, batch_size: batch_size)
    end

    def scheduled_replicable_ids(replicable_name)
      scheduled_jobs.select { |data| data[:replicable_name] == replicable_name }.map { |data| data[:model_record_id] }
    end

    def replicator_classes
      Gitlab::Geo.enabled_replicator_classes
    end
  end
end
