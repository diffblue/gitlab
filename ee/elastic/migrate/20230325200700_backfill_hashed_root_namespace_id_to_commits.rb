# frozen_string_literal: true

class BackfillHashedRootNamespaceIdToCommits < Elastic::Migration
  include Elastic::MigrationHelper

  batched!
  batch_size 10_000
  throttle_delay 5.seconds
  retry_on_failure

  ELASTIC_TIMEOUT = '5m'
  MAX_PROJECTS_TO_PROCESS = 50

  def migrate
    projects_in_progress = get_projects_in_progress
    set_migration_state(projects_in_progress: projects_in_progress, remaining_count: remaining_count)

    return if projects_in_progress.size >= project_limit
    return if completed?

    projects_in_progress = enqueue_tasks_for_projects(projects_in_progress)
    set_migration_state(projects_in_progress: projects_in_progress, remaining_count: remaining_count)
  end

  def completed?
    helper.refresh_index(index_name: index_name)

    log("Running the count query")
    total_remaining = remaining_count

    log("Checking to see if migration is completed", total_remaining: total_remaining)
    total_remaining == 0
  end

  def index_name
    ::Elastic::Latest::CommitConfig.index_name
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def enqueue_tasks_for_projects(projects_in_progress)
    project_ids_to_work_on = search_projects(exclude_project_ids: projects_in_progress.pluck(:project_id))
    projects = Project.id_in(project_ids_to_work_on)

    projects.each do |project|
      task_id = update_by_query(project)
      next if task_id.nil?

      projects_in_progress << { task_id: task_id, project_id: project.id.to_s }
      break if projects_in_progress.size >= project_limit
    end

    # the rid field is mapped as a keyword field, so it is returned as a string
    projects_missing_from_index = project_ids_to_work_on.map(&:to_i) - projects.pluck(:id)
    projects_missing_from_index.each do |project_id|
      log_warn('Project not found. Scheduling ElasticDeleteProjectWorker', project_id: project_id)
      es_id = ::Gitlab::Elastic::Helper.build_es_id(es_type: Project.es_type, target_id: project_id)
      ElasticDeleteProjectWorker.perform_async(project_id, es_id)
    end

    projects_in_progress
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def get_projects_in_progress
    projects_in_progress = migration_state[:projects_in_progress]

    return [] if projects_in_progress.blank?

    projects_in_progress - get_failed_or_completed_projects(projects_in_progress)
  end

  def get_failed_or_completed_projects(projects)
    failed_or_completed_projects = []
    projects.each do |item|
      project_id = item[:project_id]
      task_id = item[:task_id]
      begin
        task_status = helper.task_status(task_id: task_id)
      rescue ::Elasticsearch::Transport::Transport::Errors::NotFound

        log_warn("Failed to fetch task_status", project_id: project_id, search_task_id: task_id)
        failed_or_completed_projects << item
        next
      end

      if task_status['error'].present?
        log_warn("Failed to update commits",
          project_id: project_id,
          search_task_id: task_id,
          error_type: task_status.dig('error', 'type'),
          error_reason: task_status.dig('error', 'reason')
        )

        failed_or_completed_projects << item
        next
      end

      if task_status['completed'].present?
        log("Completed: backfill hashed_root_namespace_id in commits index",
          project_id: project_id,
          search_task_id: task_id
        )

        failed_or_completed_projects << item
      else
        log("In Progress: backfill hashed_root_namespace_id in commits index",
          project_id: project_id,
          search_task_id: task_id
        )
      end
    end

    failed_or_completed_projects
  end

  def update_by_query(project)
    query = query_missing_field
    query[:bool][:filter] = { term: { rid: project.id } }
    response = client.update_by_query(
      index: index_name,
      body: {
        query: query,
        script: {
          lang: 'painless',
          source: "ctx._source.hashed_root_namespace_id = #{project.namespace.hashed_root_namespace_id}"
        }
      },
      wait_for_completion: false,
      max_docs: batch_size,
      timeout: ELASTIC_TIMEOUT,
      routing: project.es_id,
      conflicts: 'proceed'
    )

    if response['failures'].present?
      log_warn("update_by_query failed", project_id: project.id, error_message: response['failures'])
      return
    end

    # consider doing a rescue
    response['task']
  end

  def remaining_count
    client.count(
      index: index_name,
      body: {
        query: query_missing_field
      }
    )['count']
  end

  def search_projects(exclude_project_ids:)
    results = client.search(
      index: index_name,
      body: {
        size: 0,
        query: query_missing_field(exclude_project_ids),
        aggs: {
          project_ids: {
            terms: {
              size: MAX_PROJECTS_TO_PROCESS * 2,
              field: 'rid'
            }
          }
        }
      }
    )
    project_ids_hist = results.dig('aggregations', 'project_ids', 'buckets') || []
    project_ids_hist.pluck('key') # rubocop: disable CodeReuse/ActiveRecord
  end

  def query_missing_field(exclude_project_ids = nil)
    {
      bool: {
        must_not: [{ exists: { field: 'hashed_root_namespace_id' } }]
      }
    }.tap do |query|
      query[:bool][:must_not] << { terms: { rid: exclude_project_ids } } if exclude_project_ids.present?
    end
  end

  def client
    @client ||= ::Gitlab::Search::Client.new
  end

  def project_limit
    [get_number_of_shards(index_name: index_name), MAX_PROJECTS_TO_PROCESS].min
  end
end
