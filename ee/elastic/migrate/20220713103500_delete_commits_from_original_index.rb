# frozen_string_literal: true

class DeleteCommitsFromOriginalIndex < Elastic::Migration
  include Elastic::MigrationHelper

  batched!
  throttle_delay 3.minutes
  retry_on_failure

  QUERY_BODY = {
    query: {
      term: {
        type: 'commit'
      }
    }
  }.freeze

  def migrate
    task_id = migration_state[:task_id]

    if task_id
      task_status = helper.task_status(task_id: task_id)

      log_raise "Failed to delete commits: #{task_status['failures']}" if task_status['failures'].present?

      if task_status['completed']
        log "Removing commits from the original index is completed for task_id:#{task_id}"

        set_migration_state(task_id: nil)
      else
        log "Removing commits from the original index is still in progress for task_id:#{task_id}"
      end

      return
    end

    if completed?
      log "There are no commits to remove from original index"
      return
    end

    log "Launching delete by query"
    response = client.delete_by_query(
      index: helper.target_name,
      body: QUERY_BODY,
      conflicts: 'proceed',
      wait_for_completion: false,
      slices: get_number_of_shards(index_name: helper.target_name)
    )

    if response['failures'].present?
      log_raise "Failed to delete commits with task_id:#{task_id} - #{response['failures']}"
    end

    task_id = response['task']
    log "Removing commits from the original index is started with task_id:#{task_id}"

    set_migration_state(
      task_id: task_id
    )
  rescue StandardError => e
    set_migration_state(task_id: nil)

    raise e
  end

  def completed?
    helper.refresh_index

    total_remaining = original_documents_count

    log "Checking to see if migration is completed based on index counts remaining:#{total_remaining}"

    total_remaining == 0
  end

  private

  def document_type
    :commit
  end
end
