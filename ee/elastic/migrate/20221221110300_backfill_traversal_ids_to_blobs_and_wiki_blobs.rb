# frozen_string_literal: true

class BackfillTraversalIdsToBlobsAndWikiBlobs < Elastic::Migration
  include Elastic::MigrationHelper

  batch_size 100_000
  ELASTIC_TIMEOUT = '5m'
  BLOB_AND_WIKI_BLOB = %w[blob wiki_blob].freeze
  batched!
  throttle_delay 45.seconds
  retry_on_failure

  def migrate
    task_id = migration_state[:task_id]

    if task_id
      task_status = helper.task_status(task_id: task_id)

      if task_status['failures'].present?
        set_migration_state(task_id: nil)
        log_raise "Failed to update projects : #{task_status['failures']}"
      end

      if task_status['completed'].present?
        log "Updating traversal_ids in original index is completed for task_id:#{task_id}"
        set_migration_state(task_id: nil)
      else
        log "Updating traversal_ids in original index is still in progress for task_id: #{task_id}"
      end

      return
    end

    if completed?
      log "Migration Completed: There are no projects left to add traversal_ids"
      return
    end

    log "Searching for the projects with missing traversal_ids"
    project_ids = projects_with_missing_traversal_ids
    log "Found #{project_ids.size} projects with missing traversal_ids"
    project_ids.each do |project_id|
      update_by_query(Project.find(project_id))
    rescue ActiveRecord::RecordNotFound
      log "Project not found: #{project_ids[0]}"
    end
  end

  def completed?
    helper.refresh_index(index_name: helper.target_name)
    log "Running the count_items_missing_traversal_ids query"
    total_remaining = count_items_missing_traversal_ids

    log "Checking to see if migration is completed based on index counts remaining: #{total_remaining}"
    total_remaining == 0
  end

  private

  def update_by_query(project)
    log "Launching update query for project #{project.id}"
    response = client.update_by_query(
      index: helper.target_name,
      body: {
        query: {
          bool: {
            filter: [
              { term: { project_id: project.id } },
              { terms: { type: BLOB_AND_WIKI_BLOB } }
            ]
          }
        },
        script: {
          lang: "painless",
          source: "ctx._source.traversal_ids = '#{project.namespace_ancestry}'"
        }
      },
      wait_for_completion: false,
      timeout: ELASTIC_TIMEOUT,
      conflicts: 'proceed'
    )

    if response['failures'].present?
      set_migration_state(task_id: nil)
      log_raise "Failed to update project with project_id: #{project.id} - #{response['failures']}"
    end

    task_id = response['task']
    log "Adding traversal_ids to original index is started with task_id: #{task_id}"

    set_migration_state(
      task_id: task_id
    )
  rescue StandardError => e
    set_migration_state(task_id: nil)
    raise e
  end

  def count_items_missing_traversal_ids
    client.count(
      index: helper.target_name,
      body: {
        query: query_missing_traversal_ids
      }
    )['count']
  end

  def projects_with_missing_traversal_ids
    results = client.search(
      index: helper.target_name,
      body: {
        size: 0,
        query: query_missing_traversal_ids,
        aggs: {
          project_ids: {
            terms: { size: batch_size, field: "project_id" }
          }
        }
      }
    )
    project_ids_hist = results.dig('aggregations', 'project_ids', 'buckets') || []
    project_ids_hist.pluck("key") # rubocop: disable CodeReuse/ActiveRecord
  end

  def query_missing_traversal_ids
    {
      bool: {
        must_not: { exists: { field: "traversal_ids" } },
        must: { terms: { type: BLOB_AND_WIKI_BLOB } }
      }
    }
  end
end
