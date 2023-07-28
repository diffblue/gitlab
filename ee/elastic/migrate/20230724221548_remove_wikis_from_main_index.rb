# frozen_string_literal: true

class RemoveWikisFromMainIndex < Elastic::Migration
  include Elastic::MigrationHelper

  batched!
  retry_on_failure

  ELASTIC_TIMEOUT = '5m'
  MAX_PROJECTS_TO_PROCESS = 50

  def migrate
    projects_in_progress = get_projects_in_progress
    set_migration_state(projects_in_progress: projects_in_progress, remaining_count: remaining_count)
    return if projects_in_progress.size >= project_limit || completed?

    projects_in_progress = enqueue_tasks_for_projects(projects_in_progress)
    set_migration_state(projects_in_progress: projects_in_progress, remaining_count: remaining_count)
  end

  def completed?
    total_remaining = remaining_count
    log('Checking if migration is finished', total_remaining: total_remaining)
    total_remaining == 0
  end

  private

  def index_name
    helper.target_name
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def enqueue_tasks_for_projects(projects_in_progress)
    project_ids_to_work = search_projects(exclude_project_ids: projects_in_progress.pluck(:project_id))
    project_ids_to_work.each do |project_id|
      task_id = delete_by_query(project_id)
      next if task_id.nil?

      projects_in_progress << { task_id: task_id, project_id: project_id.to_s }
      break if projects_in_progress.size >= project_limit
    end
    projects_missing_from_index = project_ids_to_work.map(&:to_i) - Project.id_in(project_ids_to_work).pluck(:id)
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
        log_warn('Failed to fetch task_status', project_id: project_id, search_task_id: task_id)
        failed_or_completed_projects << item
        next
      end

      if task_status['error'].present?
        log_warn('Failed to delete wiki_blob', project_id: project_id, search_task_id: task_id,
          error_type: task_status.dig('error', 'type'), error_reason: task_status.dig('error', 'reason'))
        failed_or_completed_projects << item
        next
      end

      if task_status['completed'].present?
        log('Completed: remove_wikis_from_main_index', project_id: project_id, search_task_id: task_id)
        failed_or_completed_projects << item
      else
        log('In Progress: remove_wikis_from_main_index', project_id: project_id, search_task_id: task_id)
      end
    end
    failed_or_completed_projects
  end

  def delete_by_query(id)
    query = query_filter_wiki_blobs
    query[:bool][:filter] << { term: { project_id: id } }
    response = client.delete_by_query(index: index_name, body: { query: query }, routing: "project_#{id}",
      wait_for_completion: false, max_docs: batch_size, timeout: ELASTIC_TIMEOUT, conflicts: 'proceed'
    )

    if response['failures'].present?
      log_warn('delete_by_query failed', project_id: id, error_message: response['failures'])
      return
    end

    response['task']
  end

  def remaining_count
    helper.refresh_index(index_name: index_name)
    client.count(index: index_name, body: { query: query_filter_wiki_blobs })['count']
  end

  def search_projects(exclude_project_ids:)
    results = client.search(index: index_name,
      body: {
        size: 0, query: query_filter_wiki_blobs(exclude_project_ids),
        aggs: { project_ids: { terms: { size: MAX_PROJECTS_TO_PROCESS * 2, field: 'project_id' } } }
      }
    )
    project_ids_hist = results.dig('aggregations', 'project_ids', 'buckets') || []
    project_ids_hist.pluck('key') # rubocop: disable CodeReuse/ActiveRecord
  end

  def query_filter_wiki_blobs(exclude_project_ids = nil)
    { bool: { filter: [{ term: { type: 'wiki_blob' } }] } }.tap do |query|
      query[:bool][:must_not] = { terms: { project_id: exclude_project_ids } } if exclude_project_ids.present?
    end
  end

  def client
    @client ||= ::Gitlab::Search::Client.new
  end

  def project_limit
    [get_number_of_shards(index_name: index_name), MAX_PROJECTS_TO_PROCESS].min
  end
end
