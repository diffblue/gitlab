# frozen_string_literal: true

class UpdateAllMirrorsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include CronjobQueue

  feature_category :source_code_management
  data_consistency :sticky, feature_flag: :load_balancing_for_update_all_mirrors_worker

  LEASE_TIMEOUT = 5.minutes
  SCHEDULE_WAIT_TIMEOUT = 4.minutes
  LEASE_KEY = 'update_all_mirrors'
  RESCHEDULE_WAIT = 1.second

  def perform
    return if Gitlab::Database.read_only?

    scheduled = 0
    with_lease do
      scheduled = schedule_mirrors!
    end

    # If we didn't get the lease, or no updates were scheduled, exit early
    return unless scheduled > 0

    # Wait to give some jobs a chance to complete
    Kernel.sleep(RESCHEDULE_WAIT)

    # If there's capacity left now (some jobs completed),
    # reschedule this job to enqueue more work.
    #
    # This is in addition to the regular (cron-like) scheduling of this job.
    UpdateAllMirrorsWorker.perform_async if Gitlab::Mirror.reschedule_immediately?
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def schedule_mirrors!
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

    if scheduled > 0
      # Wait for all ProjectImportScheduleWorker jobs to complete
      deadline = Time.current + SCHEDULE_WAIT_TIMEOUT
      sleep 1 while ProjectImportScheduleWorker.queue_size > 0 && Time.current < deadline
    end

    scheduled
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def with_lease
    if lease_uuid = try_obtain_lease
      yield
    end

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

    if check_mirror_plans_in_query?
      root_namespaces_sql = Gitlab::ObjectHierarchy
        .new(Namespace.where('id = projects.namespace_id'))
        .roots
        .select(:id)
        .to_sql

      root_namespaces_join = "INNER JOIN namespaces AS root_namespaces ON root_namespaces.id = (#{root_namespaces_sql})"

      relation = relation
        .joins(root_namespaces_join)
        .joins('LEFT JOIN gitlab_subscriptions ON gitlab_subscriptions.namespace_id = root_namespaces.id')
        .joins('LEFT JOIN plans ON plans.id = gitlab_subscriptions.hosted_plan_id')
        .where(['plans.name IN (?) OR projects.visibility_level = ?', ::Plan::PAID_HOSTED_PLANS, ::Gitlab::VisibilityLevel::PUBLIC])
    end

    relation
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def schedule_projects_in_batch(projects)
    ProjectImportScheduleWorker.bulk_perform_async_with_contexts(
      projects,
      arguments_proc: -> (project) { project.id },
      context_proc: -> (project) { { project: project } }
    )
  end

  def check_mirror_plans_in_query?
    ::Gitlab::CurrentSettings.should_check_namespace_plan?
  end
end
