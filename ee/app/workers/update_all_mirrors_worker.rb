# frozen_string_literal: true

class UpdateAllMirrorsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  include CronjobQueue

  feature_category :source_code_management
  data_consistency :sticky

  LEASE_TIMEOUT = 5.minutes
  SCHEDULE_WAIT_TIMEOUT = 2.minutes
  LEASE_KEY = 'update_all_mirrors'
  RESCHEDULE_WAIT = 1.second

  def perform
    return if Gitlab::Database.read_only?

    scheduled = 0
    with_lease do
      scheduled = schedule_mirrors!

      if scheduled > 0
        # Wait for all ProjectImportScheduleWorker jobs to be picked up
        deadline = Time.current + SCHEDULE_WAIT_TIMEOUT
        sleep 1 while pending_project_import_scheduling? && Time.current < deadline
      end
    end

    # If we didn't get the lease, or no updates were scheduled, exit early
    return unless scheduled > 0

    # Wait to give some jobs a chance to complete
    sleep(RESCHEDULE_WAIT)

    # If there's capacity left now (some jobs completed),
    # reschedule this job to enqueue more work.
    #
    # This is in addition to the regular (cron-like) scheduling of this job.
    UpdateAllMirrorsWorker.perform_async if Gitlab::Mirror.reschedule_immediately?
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def schedule_mirrors!
    # Clean up mirror scheduling counter before schedule mirrors. After this job is executed, there are some cases:
    # - There are no projects to be scheduled, the job exits early, the counter is not used.
    # - All projects transition to scheduled states. The counter must be equal to 0.
    # - The timeout of 4 minutes is exceeded. In this case, another job will be
    #   rescheduled, regardless of the value of the counter.
    # Therefore, the scheduling counter should reset the counter before entering
    # the scheduling phase. In addition, this clean-up task prevents a project
    # id from being stuck in the list forever.
    ::Gitlab::Mirror.reset_scheduling

    capacity = Gitlab::Mirror.available_capacity

    # Ignore mirrors that become due for scheduling once work begins, so we
    # can't end up in an infinite loop
    now = Time.current
    last = nil
    scheduled = 0

    # On GitLab.com, we stopped processing free mirrors for private
    # projects on 2020-03-27. Including mirrors with
    # next_execution_timestamp of that date or earlier in the query will
    # lead to higher query times:
    # <https://gitlab.com/gitlab-org/gitlab/-/issues/216252>
    #
    # We should remove this workaround in favour of a simpler solution:
    # <https://gitlab.com/gitlab-org/gitlab/-/issues/216783>
    #
    last = Time.utc(2020, 3, 28) if Gitlab.com?

    while capacity > 0
      batch_size = [capacity * 2, 500].min
      projects = pull_mirrors_batch(freeze_at: now, batch_size: batch_size, offset_at: last).to_a
      break if projects.empty?

      projects_to_schedule = projects.lazy.select(&:mirror?).take(capacity).force

      capacity -= projects_to_schedule.size

      schedule_projects_in_batch(projects_to_schedule)

      scheduled += projects_to_schedule.length

      # If fewer than `batch_size` projects were returned, we don't need to query again
      break if projects.length < batch_size

      last = projects.last.import_state.next_execution_timestamp
    end

    scheduled
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def with_lease
    lease_uuid = try_obtain_lease
    yield if lease_uuid

    lease_uuid
  ensure
    cancel_lease(lease_uuid) if lease_uuid
  end

  def try_obtain_lease
    ::Gitlab::ExclusiveLease.new(LEASE_KEY, timeout: LEASE_TIMEOUT).try_obtain
  end

  def cancel_lease(uuid)
    ::Gitlab::ExclusiveLease.cancel(LEASE_KEY, uuid)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def pull_mirrors_batch(freeze_at:, batch_size:, offset_at: nil)
    relation = Project
      .non_archived
      .without_deleted
      .mirrors_to_sync(freeze_at)
      .reorder('import_state.next_execution_timestamp')
      .limit(batch_size)
      .with_route
      .with_namespace # Used by `project.mirror?`

    relation = relation.where('import_state.next_execution_timestamp > ?', offset_at) if offset_at

    relation
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def schedule_projects_in_batch(projects)
    return if projects.empty?

    # projects were materialized at this stage
    ::Gitlab::Mirror.track_scheduling(projects.map(&:id))

    ProjectImportScheduleWorker.bulk_perform_async_with_contexts(
      projects,
      arguments_proc: -> (project) { project.id },
      context_proc: -> (project) { { project: project } }
    )
  end

  def pending_project_import_scheduling?
    ::Gitlab::Mirror.current_scheduling > 0
  end
end
