# frozen_string_literal: true

class DeleteNotesFromOriginalIndex < Elastic::Migration
  batched!
  throttle_delay 3.minutes
  retry_on_failure

  QUERY_BODY = {
    query: {
      term: {
        type: 'note'
      }
    }
  }.freeze

  def migrate
    task_id = migration_state[:task_id]

    if task_id
      response = helper.task_status(task_id: task_id)

      if response['completed']
        log "Removing notes from the original index is completed for task_id:#{task_id}"

        set_migration_state(task_id: nil)

        # since delete_by_query is using wait_for_completion = false, the task must be cleaned up
        # in Elasticsearch system .tasks index
        helper.client.delete(index: '.tasks', type: 'task', id: task_id)
      else
        log "Removing notes from the original index is still in progress for task_id:#{task_id}"
      end

      log_raise "Failed to delete notes: #{response['failures']}" if response['failures'].present?

      return
    end

    if completed?
      log "Skipping removing notes from the original index since it is already applied"
      return
    end

    log "Launching delete by query"
    response = client.delete_by_query(index: helper.target_name, body: QUERY_BODY, conflicts: 'proceed', wait_for_completion: false)

    log_raise "Failed to delete notes with task_id:#{task_id} - #{response['failures']}" if response['failures'].present?

    task_id = response['task']
    log "Removing notes from the original index is started with task_id:#{task_id}"

    set_migration_state(
      task_id: task_id
    )
  rescue StandardError => e
    set_migration_state(task_id: nil)

    raise e
  end

  def completed?
    helper.refresh_index

    results = client.count(index: helper.target_name, body: QUERY_BODY)
    total_remaining = results.dig('count')
    log "Checking to see if migration is completed based on index counts remaining:#{total_remaining}"

    total_remaining == 0
  end
end
