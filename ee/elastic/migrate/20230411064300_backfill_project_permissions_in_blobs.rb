# frozen_string_literal: true

class BackfillProjectPermissionsInBlobs < Elastic::Migration
  include Elastic::MigrationHelper

  ELASTIC_TIMEOUT = '5m'
  MAX_PROJECTS_TO_PROCESS = 50

  batch_size 10_000
  batched!
  throttle_delay 5.seconds
  retry_on_failure

  def migrate
    projects_in_progress = migration_state[:projects_in_progress] || []
    if projects_in_progress.present?
      failed_or_completed_projects = process_projects_in_progress(projects_in_progress)
      projects_in_progress -= failed_or_completed_projects
      set_migration_state(projects_in_progress: projects_in_progress,
        remaining_count: count_items_missing_project_permissions)
    end

    if completed?
      log "Migration Completed: There are no blob documents with missing project permissions"
      return
    end

    project_limit = determine_project_limit
    return if projects_in_progress.size >= project_limit

    log "Enqueuing blob documents with missing project permissions"
    exclude_project_ids = projects_in_progress.pluck(:project_id) # rubocop: disable CodeReuse/ActiveRecord

    projects_with_missing_project_permissions(exclude_project_ids: exclude_project_ids).each do |project_id|
      task_id = update_by_query(Project.find(project_id))

      next if task_id.nil?

      projects_in_progress << { task_id: task_id, project_id: project_id }

      break if projects_in_progress.size >= project_limit
    rescue ActiveRecord::RecordNotFound
      log("Project not found. Scheduling ElasticDeleteProjectWorker", project_id: project_id)
      # project must be removed from the index or it will continue to show up in the missing query
      # since we do not have access to the project record, the es_id input must be constructed manually
      es_id = ::Gitlab::Elastic::Helper.build_es_id(es_type: Project.es_type, target_id: project_id)
      ElasticDeleteProjectWorker.perform_async(project_id, es_id)
    end

    set_migration_state(projects_in_progress: projects_in_progress,
      remaining_count: count_items_missing_project_permissions)
  end

  def completed?
    helper.refresh_index(index_name: helper.target_name)
    log "Running the count_items_missing_project_permissions query"
    total_remaining = count_items_missing_project_permissions
    log("Checking to see if migration is completed based on index counts", remaining: total_remaining)
    total_remaining == 0
  end

  private

  def process_projects_in_progress(projects)
    failed_or_completed_projects = []
    projects.each do |item|
      project_id = item[:project_id]
      task_id = item[:task_id]
      begin
        task_status = helper.task_status(task_id: task_id)
      rescue ::Elasticsearch::Transport::Transport::Errors::NotFound
        log_warn("Failed to fetch task status", project_id: project_id, task_id: task_id)
        failed_or_completed_projects << item
        next
      end

      if task_status['error'].present?
        log_warn("Failed to update", project_id: project_id, task_id: task_id, error: task_status['failures'])
        failed_or_completed_projects << item
        next
      end

      if task_status['completed'].present?
        log("Updating project permissions for blobs is completed", project_id: project_id, task_id: task_id)
        failed_or_completed_projects << item
      else
        log("Updating project permissions for blobs is in progress.", project_id: project_id, task_id: task_id)
      end
    end
    failed_or_completed_projects
  end

  def update_by_query(project)
    log("Launching update query", project_id: project.id)
    source = "ctx._source.repository_access_level = #{project.repository_access_level};" \
             "ctx._source.visibility_level = #{project.visibility_level};"
    response = client.update_by_query(
      index: helper.target_name,
      body: {
        query: {
          bool: {
            filter: [
              { term: { project_id: project.id } },
              { term: { type: 'blob' } }
            ]
          }
        },
        script: {
          lang: "painless",
          source: source
        }
      },
      wait_for_completion: false,
      max_docs: batch_size,
      timeout: ELASTIC_TIMEOUT,
      routing: project.es_id,
      conflicts: 'proceed'
    )

    if response['failures'].present?
      log_warn("Failed to update", project_id: project.id, error: response['failures'])
      return
    end

    response['task']
  end

  def count_items_missing_project_permissions
    client.count(
      index: helper.target_name,
      body: {
        query: query_missing_project_permissions
      }
    )['count']
  end

  def projects_with_missing_project_permissions(exclude_project_ids:)
    results = client.search(
      index: helper.target_name,
      body: {
        size: 0,
        query: query_missing_project_permissions(exclude_project_ids),
        aggs: {
          project_ids: {
            terms: {
              size: MAX_PROJECTS_TO_PROCESS * 2,
              field: "project_id"
            }
          }
        }
      }
    )
    project_ids_hist = results.dig('aggregations', 'project_ids', 'buckets') || []
    project_ids_hist.pluck("key") # rubocop: disable CodeReuse/ActiveRecord
  end

  def query_missing_project_permissions(exclude_project_ids = nil)
    query = {
      bool: {
        minimum_should_match: 1,
        should: [
          {
            bool: {
              must_not: [{ exists: { field: 'repository_access_level' } }]
            }
          },
          {
            bool: {
              must_not: [{ exists: { field: 'visibility_level' } }]
            }
          }
        ],
        filter: { term: { type: 'blob' } }
      }
    }

    query[:bool][:must_not] << { terms: { project_id: exclude_project_ids } } if exclude_project_ids.present?
    query
  end

  def client
    @client ||= ::Gitlab::Search::Client.new
  end

  def determine_project_limit
    [get_number_of_shards(index_name: helper.target_name), MAX_PROJECTS_TO_PROCESS].min
  end
end
