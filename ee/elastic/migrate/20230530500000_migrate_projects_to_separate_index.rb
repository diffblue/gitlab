# frozen_string_literal: true

class MigrateProjectsToSeparateIndex < Elastic::Migration
  include Elastic::MigrationHelper

  pause_indexing!
  batched!
  batch_size 10_000
  space_requirements!
  throttle_delay 1.minute

  MAX_ATTEMPTS_PER_SLICE = 30
  SCHEMA_VERSION = 23_06

  def migrate
    # On initial batch we only create index
    if migration_state[:slice].blank?
      create_index_for_first_batch!([Project])
      set_migration_state({ slice: 0, retry_attempt: 0, max_slices: get_max_slices })
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
      log("Checking reindexing status", slice: slice, task_id: task_id)

      if reindexing_completed?(task_id: task_id)
        log("Reindexing is completed.", slice: slice, task_id: task_id)
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

    original_count.eql?(new_count)
  end

  def space_required_bytes
    (helper.index_size_bytes * 0.01).ceil
  end

  private

  def document_type
    'project'
  end

  def document_type_fields
    %w[
      id
      name
      path
      description
      namespace_id
      created_at
      updated_at
      archived
      visibility_level
      last_activity_at
      name_with_namespace
      path_with_namespace
      type
      schema_version
      traversal_ids
      ci_catalog
      readme_content
    ]
  end

  def reindex_script
    'ctx._source.id = ctx._source.remove("id");' \
      'ctx._source.name = ctx._source.remove("name");' \
      'ctx._source.path = ctx._source.remove("path");' \
      'ctx._source.description = ctx._source.remove("description");' \
      'ctx._source.namespace_id = ctx._source.remove("namespace_id");' \
      'ctx._source.created_at = ctx._source.remove("created_at");' \
      'ctx._source.updated_at = ctx._source.remove("updated_at");' \
      'ctx._source.archived = ctx._source.remove("archived");' \
      'ctx._source.visibility_level = ctx._source.remove("visibility_level");' \
      'ctx._source.last_activity_at = ctx._source.remove("last_activity_at");' \
      'ctx._source.name_with_namespace = ctx._source.remove("name_with_namespace");' \
      'ctx._source.path_with_namespace = ctx._source.remove("path_with_namespace");' \
      'ctx._source.type = ctx._source.remove("type");' \
      'ctx._source.readme_content = ctx._source.remove("readme_content");' \
      'ctx._source.ci_catalog = ctx._source.remove("ci_catalog");' \
      'ctx._source.traversal_ids = ctx._source.remove("traversal_ids");' \
      "ctx._source.schema_version = #{SCHEMA_VERSION};" \
  end

  def new_index_name
    "#{default_index_name}-projects"
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
