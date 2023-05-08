# frozen_string_literal: true

class BackfillProjectPermissionsInBlobsUsingPermutations < Elastic::Migration
  batched!
  batch_size 10_000
  throttle_delay 1.minute

  VISIBILITY_LEVELS = ::Gitlab::VisibilityLevel.values.freeze
  PERMISSIONS_MATRIX = VISIBILITY_LEVELS.product(VISIBILITY_LEVELS).sort.freeze
  LAST_PERMUTATION_IDX = PERMISSIONS_MATRIX.length - 1
  ELASTIC_TIMEOUT = '5m'
  MAX_ATTEMPTS_PER_IDX = 30

  def migrate
    return setup unless permutation_idx.present?
    return handle_failure if failed?
    return unless visibility_level.present?
    return if completed?
    return handle_permutation_completed if permutation_completed?
    return handle_ongoing_task if task_id.present?

    launch_task
  rescue StandardError => e
    log("Update failed.", permutation_idx: permutation_idx, error: e.message)

    set_migration_state(
      permutation_idx: permutation_idx,
      retry_attempt: retry_attempt + 1,
      task_id: nil,
      documents_remaining: documents_remaining,
      documents_remaining_for_permutation: documents_remaining_for_permutation
    )

    raise e
  end

  def completed?
    doc_count = documents_remaining
    log("Checking if there are blobs without permissions set", documents_remaining: doc_count)
    doc_count == 0
  end

  def permutation_completed?
    documents_remaining_for_permutation == 0
  end

  def task_completed?(task_id:)
    response = helper.task_status(task_id: task_id)
    completed = response['completed']
    log("Task completion check", task_id: task_id, task_status: completed, permutation_idx: permutation_idx)
    return false unless completed

    stats = response['response']
    if stats['error'].present?
      log_warn("Update has failed.", task_id: task_id, error_type: stats.dig('error', 'type'),
        error_reason: stats.dig('error', 'reason'))
    end

    true
  end

  def retry_attempt
    migration_state[:retry_attempt].to_i
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

  def failed?
    retry_attempt >= MAX_ATTEMPTS_PER_IDX
  end

  def handle_failure
    fail_migration_halt_error!(retry_attempt: retry_attempt)
  end

  def index_name
    helper.target_name
  end

  def documents_remaining
    count_of_blobs_without_permissions(any_blobs_missing_permissions)
  end

  def documents_remaining_for_permutation
    filter = blobs_missing_project_permissions(
      visibility_level: visibility_level, repository_access_level: repository_access_level
    )
    count_of_blobs_without_permissions(filter)
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
  end

  def handle_permutation_completed
    set_migration_state(
      retry_attempt: 0, # We reset retry_attempt since task completed
      permutation_idx: permutation_idx + 1,
      task_id: nil,
      documents_remaining: documents_remaining,
      documents_remaining_for_permutation: documents_remaining_for_permutation
    )
  end

  def handle_ongoing_task
    if task_completed?(task_id: task_id)
      log("Update is completed", permutation_idx: permutation_idx, task_id: task_id)

      set_migration_state(
        task_id: nil,
        retry_attempt: 0, # We reset retry_attempt since task completed
        documents_remaining: documents_remaining,
        documents_remaining_for_permutation: documents_remaining_for_permutation
      )

    else
      log("Update is still in progress", permutation_idx: permutation_idx, task_id: task_id)
      set_migration_state(
        permutation_idx: permutation_idx,
        task_id: task_id,
        documents_remaining: documents_remaining,
        documents_remaining_for_permutation: documents_remaining_for_permutation
      )

    end
  end

  def launch_task
    log("Launching update_by_query", permutation_idx: permutation_idx)
    new_task_id = update_by_query(visibility_level: visibility_level, repository_access_level: repository_access_level)

    log("Task has started", permutation_idx: permutation_idx, task_id: new_task_id)

    set_migration_state(
      permutation_idx: permutation_idx,
      task_id: new_task_id,
      documents_remaining: documents_remaining,
      documents_remaining_for_permutation: documents_remaining_for_permutation
    )
  end

  def count_of_blobs_without_permissions(filter)
    helper.refresh_index(index_name: index_name)

    client.count(index: index_name, body: { query: filter })['count']
  end

  def any_blobs_missing_permissions
    {
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
        must: [
          {
            has_parent: {
              parent_type: "project",
              query: {
                match_all: {}
              }
            }
          }
        ],
        filter: { term: { type: 'blob' } }
      }
    }
  end

  def update_by_query(visibility_level:, repository_access_level:)
    query = {
      query: blobs_missing_project_permissions(
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

  def blobs_missing_project_permissions(visibility_level:, repository_access_level:)
    {
      bool: {
        filter: { term: { type: 'blob' } },
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
        must: [
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

  def client
    @client ||= ::Gitlab::Search::Client.new
  end
end
