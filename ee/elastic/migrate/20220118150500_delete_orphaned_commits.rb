# frozen_string_literal: true

class DeleteOrphanedCommits < Elastic::Migration
  retry_on_failure

  def migrate
    return if completed?

    if task_id.nil?
      set_migration_state(
        task_id: delete_by_query['task']
      )
    elsif task_failed?(task_id: task_id)
      error_message = "Delete task failed: #{task_id}"

      set_migration_state(task_id: nil) # Initiate retry
      log_raise error_message
    end
  end

  def completed?
    number_of_orphaned_commits == 0
  end

  def index_name
    helper.target_name
  end

  def task_id
    migration_state[:task_id]
  end

  def task_failed?(task_id:)
    failures = helper.task_status(task_id: task_id).dig('response', 'failures')

    if failures.present?
      log "Task with task_id:#{task_id} has failed with #{failures}"

      true
    else
      log "Task with task_id:#{task_id} has been successfully completed"

      false
    end
  end

  private

  def delete_by_query
    client.delete_by_query(
      index: index_name,
      body: orphaned_commits_query,
      wait_for_completion: false, # async task
      conflicts: 'proceed', # don't abort task if document was updated before delete.
      timeout: '3d'       # maximum time Elasticsearch will allow task to run.
    )
  end

  def orphaned_commits_query
    {
      query: {
        bool: {
          must: [
            {
              term: {
                type: {
                  value: "commit"
                }
              }
            }
          ],
          must_not: [
            {
              has_parent: {
                parent_type: "project",
                query: {
                  match_all: {}
                }
              }
            },
            {
              exists: {
                field: "visibility_level"
              }
            }
          ]
        }
      }
    }
  end

  def number_of_orphaned_commits
    helper.refresh_index
    count = client.count(index: index_name, body: orphaned_commits_query)['count']
    log "Checking the number of orphaned commits. Current count is #{count}"
    count
  end
end
