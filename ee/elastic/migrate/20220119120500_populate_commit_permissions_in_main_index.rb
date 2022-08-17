# frozen_string_literal: true

class PopulateCommitPermissionsInMainIndex < Elastic::Migration
  # This migration works by taking all possible combinations of visibility levels
  # in the PERMISSIONS_MATRIX and updating BATCH_SIZE amount of commits to reflect
  # the permissions in the PERMISSIONS_MATRIX. The current permissions settings is referred
  # to as the `permutation_idx`.
  #
  # For any given `permutation_idx`, this migration will need to be run several times.
  # - Step 0 (only on very first run): declare initial migration step
  # - Step 1: launch update_by_query task to update batch of commits within current permutation
  # - Step 2: check if update_by_query task completed
  #   - 2.A: if task is still ongoing, do nothing.
  #   - 2.B: if task is completed but there are more commits included in current permutation, repeat Step 1.
  #   - 2.C: if task is completed and all commits within permutation are updated, increment the permutation_idx.
  #
  # Note that one `migrate` is to launch the task and
  # another `migrate` is required to handle the completion of that task.
  #
  # The number of times this migration will need to be run to complete a single permutation can
  # be denoted like this mathematically:
  #
  # fx(num_commits_in_permutation) = (num_commits_in_permutation / batch_size) * 2
  #
  batched!
  batch_size 100_000
  throttle_delay 1.minute

  MAX_ATTEMPTS_PER_IDX = 30
  VISIBILITY_LEVELS = ::Gitlab::VisibilityLevel.values.freeze
  PERMISSIONS_MATRIX = VISIBILITY_LEVELS.product(VISIBILITY_LEVELS).sort.freeze
  LAST_PERMUTATION_IDX = PERMISSIONS_MATRIX.length - 1
  ELASTIC_TIMEOUT = '5m'

  def migrate
    return setup unless permutation_idx.present?
    return handle_failure if failed?
    return :noop unless visibility_level.present?
    return :completed if completed?
    return handle_permutation_completed if permutation_completed?
    return handle_ongoing_task if task_id.present?

    launch_task
    :started
  rescue StandardError => e
    log "Update failed, error: #{e.message} increasing migration_state for " \
        "permutation_idx: (#{permutation_idx}/#{LAST_PERMUTATION_IDX}) | retry_attempt: #{retry_attempt}"

    set_migration_state(
      permutation_idx: permutation_idx,
      task_id: nil,
      retry_attempt: retry_attempt + 1,
      documents_remaining: documents_remaining,
      documents_remaining_for_permutation: documents_remaining_for_permutation
    )

    raise e
  end

  def completed?
    doc_count = documents_remaining
    log "Checking if there are commits without visibility_level field: #{doc_count} documents left"
    doc_count == 0
  end

  def permutation_completed?
    documents_remaining_for_permutation == 0
  end

  def task_completed?(task_id:)
    response = helper.task_status(task_id: task_id)
    completed = response['completed']
    log "Task #{task_id} completion check: '#{completed}' (permutation #{permutation_idx}/#{LAST_PERMUTATION_IDX})"
    return false unless completed

    stats = response['response']
    if stats['failures'].present?
      log_raise "Update has failed with #{stats['failures']} failures"
    end

    true
  end

  def permutation_idx
    migration_state[:permutation_idx]
  end

  def visibility_level
    permutation[0]
  end

  def repository_access_level
    permutation[1]
  end

  def task_id
    migration_state[:task_id]
  end

  private

  def batch_num
    migration_state[:batch_num].to_i
  end

  def index_name
    helper.target_name
  end

  def retry_attempt
    migration_state[:retry_attempt].to_i
  end

  def documents_remaining
    count_of_commits_without_permissions(any_commits_missing_visibility_level)
  end

  def documents_remaining_for_permutation
    filter = commits_missing_project_access_levels(
      visibility_level: visibility_level, repository_access_level: repository_access_level
    )
    count_of_commits_without_permissions(filter)
  end

  def failed?
    retry_attempt >= MAX_ATTEMPTS_PER_IDX
  end

  def handle_failure
    fail_migration_halt_error!(retry_attempt: retry_attempt)
  end

  def permutation
    PERMISSIONS_MATRIX[permutation_idx] || [nil, nil]
  end

  def setup
    # do not include documents_remaining_for_permutation on setup to avoid nil error when
    # pulling visibility_level and repository_access_level for the current permutation
    set_migration_state(
      retry_attempt: 0,
      permutation_idx: 0,
      documents_remaining: documents_remaining
    )

    :setup
  end

  def handle_permutation_completed
    set_migration_state(
      permutation_idx: permutation_idx + 1,
      batch_num: 0,
      task_id: nil,
      retry_attempt: 0, # We reset retry_attempt since task completed
      documents_remaining: documents_remaining,
      documents_remaining_for_permutation: documents_remaining_for_permutation
    )

    :permutation_completed
  end

  def handle_ongoing_task
    if task_completed?(task_id: task_id)
      log "Update is completed for permutation_idx: (#{permutation_idx}/#{LAST_PERMUTATION_IDX}) | " \
          "retry_attempt: #{retry_attempt} | task_id: #{task_id}"

      set_migration_state(
        task_id: nil,
        retry_attempt: 0, # We reset retry_attempt since task completed
        batch_num: batch_num + 1,
        documents_remaining: documents_remaining,
        documents_remaining_for_permutation: documents_remaining_for_permutation
      )

      :task_completed
    else
      log "Update is still in progress for permutation_idx: (#{permutation_idx}/#{LAST_PERMUTATION_IDX}) | " \
          "retry_attempt: #{retry_attempt} | task_id: #{task_id}"
      :in_progress
    end
  end

  def launch_task
    log "Launching update_by_query for permutation_idx: (#{permutation_idx}/#{LAST_PERMUTATION_IDX}) | " \
        "retry_attempt: #{retry_attempt}"
    new_task_id = update_by_query(visibility_level: visibility_level, repository_access_level: repository_access_level)

    log "Task has started for permutation_idx: (#{permutation_idx}/#{LAST_PERMUTATION_IDX}) | " \
        "retry_attempt: #{retry_attempt} | task_id: #{new_task_id}"

    set_migration_state(
      permutation_idx: permutation_idx,
      task_id: new_task_id,
      documents_remaining: documents_remaining,
      documents_remaining_for_permutation: documents_remaining_for_permutation
    )
  end

  def count_of_commits_without_permissions(filter)
    helper.refresh_index(index_name: index_name)

    query = {
      size: 0,
      aggs: {
        commits_missing_visibility_level: {
          filter: filter
        }
      }
    }

    results = client.search(index: index_name, body: query)
    results.dig('aggregations', 'commits_missing_visibility_level', 'doc_count')
  end

  def any_commits_missing_visibility_level
    {
      bool: {
        must: [
          {
            term: {
              type: {
                value: "commit"
              }
            }
          },
          {
            has_parent: {
              parent_type: "project",
              query: {
                match_all: {}
              }
            }
          }
        ],
        must_not: [
          {
            exists: {
              field: "visibility_level"
            }
          }
        ]
      }
    }
  end

  def update_by_query(visibility_level:, repository_access_level:)
    query = {
      query: commits_missing_project_access_levels(
        visibility_level: visibility_level, repository_access_level: repository_access_level
      ),
      script: {
        lang: 'painless',
        source: "ctx._source.visibility_level = #{visibility_level};" \
                "ctx._source.repository_access_level = #{repository_access_level}"
      }
    }

    response = client.update_by_query(
      index: index_name,
      body: query,
      wait_for_completion: false,
      max_docs: batch_size,
      timeout: ELASTIC_TIMEOUT,
      conflicts: 'proceed'
    )
    response['task']
  end

  def commits_missing_project_access_levels(visibility_level:, repository_access_level:)
    {
      bool: {
        must_not: [
          {
            exists: {
              field: "visibility_level"
            }
          }
        ],
        must: [
          {
            term: {
              type: {
                value: "commit"
              }
            }
          },
          {
            has_parent: {
              parent_type: "project",
              query: {
                bool: {
                  must: [
                    {
                      term: {
                        visibility_level: {
                          value: visibility_level
                        }
                      }
                    },
                    {
                      term: {
                        repository_access_level: {
                          value: repository_access_level
                        }
                      }
                    }
                  ]
                }
              }
            }
          }
        ]
      }
    }
  end
end
