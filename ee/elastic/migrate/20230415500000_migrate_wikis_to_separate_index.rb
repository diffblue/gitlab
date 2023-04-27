# frozen_string_literal: true

class MigrateWikisToSeparateIndex < Elastic::Migration
  include Elastic::MigrationHelper

  pause_indexing!
  batched!
  batch_size 10_000
  space_requirements!
  throttle_delay 1.minute

  MAX_ATTEMPTS_PER_SLICE = 30
  SCHEMA_VERSION = 23_04

  def migrate
    # On initial batch we only create index
    if migration_state[:slice].blank?
      create_index_for_first_batch!([Wiki])
      set_migration_state({ slice: 0, retry_attempt: 0, max_slices: get_number_of_shards })
      return
    end

    retry_attempt = migration_state[:retry_attempt]
    slice = migration_state[:slice]
    task_id = migration_state[:task_id]
    max_slices = migration_state[:max_slices]

    if retry_attempt >= MAX_ATTEMPTS_PER_SLICE
      fail_migration_halt_error!(retry_attempt: retry_attempt)
      return
    end

    return if slice >= max_slices

    if task_id
      log "Checking reindexing status for slice: #{slice} | task_id: #{task_id}"

      if reindexing_completed?(task_id: task_id)
        log "Reindexing is completed for slice: #{slice} | task_id: #{task_id}"
        set_migration_state_for_next_slice slice + 1
      else
        log "Reindexing is still in progress for slice: #{slice} | task_id: #{task_id}"
      end

      return
    end

    log "Launching reindexing for slice: #{slice} | max_slices: #{max_slices}"

    task_id = reindex(slice: slice, max_slices: max_slices, script: reindex_script)

    log "Reindexing for slice: #{slice} | max_slices: #{max_slices} is started with task_id: #{task_id}"

    set_migration_state(slice: slice, task_id: task_id, max_slices: max_slices)
  rescue StandardError => e
    log "migrate failed, increasing migration_state for slice: #{slice} " \
        "retry_attempt: #{retry_attempt} error: #{e.message}"

    set_migration_state(slice: slice, task_id: nil, retry_attempt: retry_attempt + 1, max_slices: max_slices)

    raise e
  end

  def completed?
    original_count = original_documents_count
    new_count = new_documents_count
    log "Checking to see if migration is completed based on index counts: " \
        "original_count: #{original_count}, new_count: #{new_count}"

    original_count.eql? new_count
  end

  def space_required_bytes
    # wiki documents on GitLab.com takes at most 1% of the main index storage
    # this migration will require a small buffer
    (helper.index_size_bytes * 0.01).ceil
  end

  private

  def document_type
    'wiki_blob'
  end

  def document_type_fields
    %w[type project_id traversal_ids blob visibility_level wiki_access_level]
  end

  def reindex_script
    'ctx._source.rid = ctx._source.blob.remove("rid");' \
      'ctx._source.oid = ctx._source.blob.remove("oid");' \
      'ctx._source.commit_sha = ctx._source.blob.remove("commit_sha");' \
      'ctx._source.path = ctx._source.blob.remove("path");' \
      'ctx._source.file_name = ctx._source.blob.remove("file_name");' \
      'ctx._source.content = ctx._source.blob.remove("content");' \
      'ctx._source.language = ctx._source.blob.remove("language");' \
      "ctx._source.schema_version = #{SCHEMA_VERSION};" \
      'ctx._source.remove("blob")'
  end

  def new_index_name
    "#{default_index_name}-wikis"
  end

  def set_migration_state_for_next_slice(slice)
    set_migration_state(
      slice: slice,
      task_id: nil,
      retry_attempt: 0,
      max_slices: migration_state[:max_slices]
    )
  end
end
