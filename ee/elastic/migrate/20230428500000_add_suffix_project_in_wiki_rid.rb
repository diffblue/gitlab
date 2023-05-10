# frozen_string_literal: true

class AddSuffixProjectInWikiRid < Elastic::Migration
  include Elastic::MigrationHelper

  pause_indexing!
  batched!
  space_requirements!
  throttle_delay 1.minute

  ELASTIC_TIMEOUT = '5m'
  MAX_ATTEMPTS_PER_SLICE = 30

  def migrate
    retry_attempt, slice, task_id, max_slices = set_vars

    if retry_attempt >= MAX_ATTEMPTS_PER_SLICE
      fail_migration_halt_error!(retry_attempt: retry_attempt)
      return
    end

    return if slice >= max_slices

    if task_id
      process_already_started_task(task_id, slice)
      return
    end

    log('Launching reindexing', slice: slice, max_slices: max_slices)
    response = update_by_query(slice, max_slices)

    task_id = response['task']

    log('Reindexing for slice is started', slice: slice, max_slices: max_slices, task_id: task_id)

    set_migration_state(slice: slice, task_id: task_id, max_slices: max_slices,
      remaining_document_count: count_items_missing_prefix_in_rid)
  rescue StandardError => e
    log('migration failed, increasing migration_state', slice: slice, retry_attempt: retry_attempt, error: e.message)

    set_migration_state(slice: slice, task_id: nil, retry_attempt: retry_attempt + 1, max_slices: max_slices)

    raise e
  end

  def completed?
    total_remaining = count_items_missing_prefix_in_rid

    log('Checking if migration is finished based on index counts remaining', total_remaining: total_remaining)
    total_remaining.eql?(0)
  end

  def space_required_bytes
    # wiki documents on GitLab.com takes at most 1% of the main index storage
    # this migration will require a small buffer
    (helper.index_size_bytes * 0.01).ceil
  end

  private

  def index_name
    Elastic::Latest::WikiConfig.index_name
  end

  def count_items_missing_prefix_in_rid
    helper.refresh_index(index_name: index_name)
    client.count(index: index_name, body: { query: query })['count']
  end

  def query
    { regexp: { rid: "wiki_[0-9].*" } }
  end

  def set_migration_state_for_next_slice(slice)
    set_migration_state(
      slice: slice,
      task_id: nil,
      retry_attempt: 0,
      max_slices: migration_state[:max_slices]
    )
  end

  def update_by_query(slice, max_slices)
    client.update_by_query(
      index: index_name,
      body: {
        query: query,
        script: { lang: 'painless', source: "ctx._source.rid = ctx._source.rid.replace('wiki', 'wiki_project')" },
        slice: { id: slice, max: max_slices }
      },
      wait_for_completion: false,
      timeout: ELASTIC_TIMEOUT,
      conflicts: 'proceed'
    )
  end

  def set_vars
    retry_attempt = migration_state[:retry_attempt] || 0
    slice = migration_state[:slice] || 0
    task_id = migration_state[:task_id]
    max_slices = migration_state[:max_slices] || get_number_of_shards(index_name: index_name)
    [retry_attempt, slice, task_id, max_slices]
  end

  def process_already_started_task(task_id, slice)
    log('Checking reindexing status', slice: slice, task_id: task_id)

    if reindexing_completed?(task_id: task_id)
      log('Reindexing is completed', slice: slice, task_id: task_id)
      set_migration_state_for_next_slice(slice + 1)
    else
      log('Reindexing is still in progress', slice: slice, task_id: task_id)
    end
  end
end
