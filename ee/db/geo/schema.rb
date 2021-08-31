# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_08_20_152707) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "container_repository_registry", id: :serial, force: :cascade do |t|
    t.integer "container_repository_id", null: false
    t.string "state"
    t.integer "retry_count", default: 0
    t.string "last_sync_failure"
    t.datetime "retry_at"
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.index ["container_repository_id"], name: "index_container_repository_registry_repository_id_unique", unique: true
    t.index ["retry_at"], name: "index_container_repository_registry_on_retry_at"
    t.index ["state"], name: "index_container_repository_registry_on_state"
  end

  create_table "design_registry", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "state", limit: 20
    t.integer "retry_count", default: 0
    t.string "last_sync_failure"
    t.boolean "force_to_redownload"
    t.boolean "missing_on_primary"
    t.datetime "retry_at"
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.index ["project_id"], name: "index_design_registry_on_project_id", unique: true
    t.index ["retry_at"], name: "index_design_registry_on_retry_at"
    t.index ["state"], name: "index_design_registry_on_state"
  end

  create_table "event_log_states", primary_key: "event_id", force: :cascade do |t|
    t.datetime "created_at", null: false
  end

  create_table "file_registry", id: :serial, force: :cascade do |t|
    t.string "file_type", null: false
    t.integer "file_id", null: false
    t.bigint "bytes"
    t.string "sha256"
    t.datetime "created_at", null: false
    t.boolean "success", default: false, null: false
    t.integer "retry_count"
    t.datetime "retry_at"
    t.boolean "missing_on_primary", default: false, null: false
    t.index ["file_type", "file_id"], name: "index_file_registry_on_file_type_and_file_id", unique: true
    t.index ["file_type"], name: "index_file_registry_on_file_type"
    t.index ["retry_at"], name: "index_file_registry_on_retry_at"
    t.index ["success"], name: "index_file_registry_on_success"
  end

  create_table "group_wiki_repository_registry", force: :cascade do |t|
    t.datetime_with_timezone "retry_at"
    t.datetime_with_timezone "last_synced_at"
    t.datetime_with_timezone "created_at", null: false
    t.bigint "group_wiki_repository_id", null: false
    t.integer "state", limit: 2, default: 0, null: false
    t.integer "retry_count", limit: 2, default: 0
    t.text "last_sync_failure"
    t.boolean "force_to_redownload"
    t.boolean "missing_on_primary"
    t.index ["group_wiki_repository_id"], name: "index_g_wiki_repository_registry_on_group_wiki_repository_id", unique: true
    t.index ["retry_at"], name: "index_group_wiki_repository_registry_on_retry_at"
    t.index ["state"], name: "index_group_wiki_repository_registry_on_state"
  end

  create_table "job_artifact_registry", id: :serial, force: :cascade do |t|
    t.datetime_with_timezone "created_at"
    t.datetime_with_timezone "retry_at"
    t.bigint "bytes"
    t.integer "artifact_id"
    t.integer "retry_count"
    t.boolean "success"
    t.string "sha256"
    t.boolean "missing_on_primary", default: false, null: false
    t.index ["artifact_id"], name: "index_job_artifact_registry_on_artifact_id"
    t.index ["retry_at"], name: "index_job_artifact_registry_on_retry_at"
    t.index ["success"], name: "index_job_artifact_registry_on_success"
  end

  create_table "lfs_object_registry", force: :cascade do |t|
    t.datetime_with_timezone "created_at"
    t.datetime_with_timezone "retry_at"
    t.bigint "bytes"
    t.integer "lfs_object_id"
    t.integer "retry_count", default: 0
    t.boolean "missing_on_primary", default: false, null: false
    t.boolean "success", default: false, null: false
    t.binary "sha256"
    t.integer "state", limit: 2, default: 0, null: false
    t.datetime_with_timezone "last_synced_at"
    t.text "last_sync_failure"
    t.index ["lfs_object_id"], name: "index_lfs_object_registry_on_lfs_object_id", unique: true
    t.index ["retry_at"], name: "index_lfs_object_registry_on_retry_at"
    t.index ["state"], name: "index_state_in_lfs_objects"
    t.index ["success"], name: "index_lfs_object_registry_on_success"
  end

  create_table "merge_request_diff_registry", force: :cascade do |t|
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "retry_at"
    t.datetime_with_timezone "last_synced_at"
    t.bigint "merge_request_diff_id", null: false
    t.integer "state", limit: 2, default: 0, null: false
    t.integer "retry_count", limit: 2, default: 0
    t.text "last_sync_failure"
    t.datetime_with_timezone "verification_started_at"
    t.datetime_with_timezone "verified_at"
    t.datetime_with_timezone "verification_retry_at"
    t.integer "verification_retry_count"
    t.integer "verification_state", limit: 2, default: 0, null: false
    t.boolean "checksum_mismatch"
    t.binary "verification_checksum"
    t.binary "verification_checksum_mismatched"
    t.string "verification_failure", limit: 255
    t.index ["merge_request_diff_id"], name: "index_merge_request_diff_registry_on_mr_diff_id", unique: true
    t.index ["retry_at"], name: "index_merge_request_diff_registry_on_retry_at"
    t.index ["state"], name: "index_merge_request_diff_registry_on_state"
    t.index ["verification_retry_at"], name: "merge_request_diff_registry_failed_verification", order: "NULLS FIRST", where: "((state = 2) AND (verification_state = 3))"
    t.index ["verification_state"], name: "merge_request_diff_registry_needs_verification", where: "((state = 2) AND (verification_state = ANY (ARRAY[0, 3])))"
    t.index ["verified_at"], name: "merge_request_diff_registry_pending_verification", order: "NULLS FIRST", where: "((state = 2) AND (verification_state = 0))"
  end

  create_table "package_file_registry", id: :serial, force: :cascade do |t|
    t.integer "package_file_id", null: false
    t.integer "state", default: 0, null: false
    t.integer "retry_count", default: 0
    t.string "last_sync_failure", limit: 255
    t.datetime_with_timezone "retry_at"
    t.datetime_with_timezone "last_synced_at"
    t.datetime_with_timezone "created_at", null: false
    t.string "verification_failure", limit: 255
    t.binary "verification_checksum"
    t.boolean "checksum_mismatch"
    t.binary "verification_checksum_mismatched"
    t.integer "verification_retry_count"
    t.datetime_with_timezone "verified_at"
    t.datetime_with_timezone "verification_retry_at"
    t.integer "verification_state", limit: 2, default: 0, null: false
    t.datetime_with_timezone "verification_started_at"
    t.index ["package_file_id"], name: "index_package_file_registry_on_repository_id"
    t.index ["retry_at"], name: "index_package_file_registry_on_retry_at"
    t.index ["state"], name: "index_package_file_registry_on_state"
    t.index ["verification_retry_at"], name: "package_file_registry_failed_verification", order: "NULLS FIRST", where: "((state = 2) AND (verification_state = 3))"
    t.index ["verification_state"], name: "package_file_registry_needs_verification", where: "((state = 2) AND (verification_state = ANY (ARRAY[0, 3])))"
    t.index ["verified_at"], name: "package_file_registry_pending_verification", order: "NULLS FIRST", where: "((state = 2) AND (verification_state = 0))"
  end

  create_table "pages_deployment_registry", force: :cascade do |t|
    t.bigint "pages_deployment_id", null: false
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "last_synced_at"
    t.datetime_with_timezone "retry_at"
    t.integer "state", limit: 2, default: 0, null: false
    t.integer "retry_count", limit: 2, default: 0, null: false
    t.string "last_sync_failure", limit: 255
    t.index ["pages_deployment_id"], name: "index_pages_deployment_registry_on_pages_deployment_id", unique: true
    t.index ["retry_at"], name: "index_pages_deployment_registry_on_retry_at"
    t.index ["state"], name: "index_pages_deployment_registry_on_state"
  end

  create_table "pipeline_artifact_registry", force: :cascade do |t|
    t.bigint "pipeline_artifact_id", null: false
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "last_synced_at"
    t.datetime_with_timezone "retry_at"
    t.datetime_with_timezone "verified_at"
    t.datetime_with_timezone "verification_started_at"
    t.datetime_with_timezone "verification_retry_at"
    t.integer "state", limit: 2, default: 0, null: false
    t.integer "verification_state", limit: 2, default: 0, null: false
    t.integer "retry_count", limit: 2, default: 0
    t.integer "verification_retry_count", limit: 2, default: 0
    t.boolean "checksum_mismatch", default: false, null: false
    t.binary "verification_checksum"
    t.binary "verification_checksum_mismatched"
    t.string "verification_failure", limit: 255
    t.string "last_sync_failure", limit: 255
    t.index ["pipeline_artifact_id"], name: "index_pipeline_artifact_registry_on_pipeline_artifact_id", unique: true
    t.index ["retry_at"], name: "index_pipeline_artifact_registry_on_retry_at"
    t.index ["state"], name: "index_pipeline_artifact_registry_on_state"
    t.index ["verification_retry_at"], name: "pipeline_artifact_registry_failed_verification", order: "NULLS FIRST", where: "((state = 2) AND (verification_state = 3))"
    t.index ["verification_state"], name: "pipeline_artifact_registry_needs_verification", where: "((state = 2) AND (verification_state = ANY (ARRAY[0, 3])))"
    t.index ["verified_at"], name: "pipeline_artifact_registry_pending_verification", order: "NULLS FIRST", where: "((state = 2) AND (verification_state = 0))"
  end

  create_table "project_registry", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.datetime "last_repository_synced_at"
    t.datetime "last_repository_successful_sync_at"
    t.datetime "created_at", null: false
    t.boolean "resync_repository", default: true, null: false
    t.boolean "resync_wiki", default: true, null: false
    t.datetime "last_wiki_synced_at"
    t.datetime "last_wiki_successful_sync_at"
    t.integer "repository_retry_count"
    t.datetime "repository_retry_at"
    t.boolean "force_to_redownload_repository"
    t.integer "wiki_retry_count"
    t.datetime "wiki_retry_at"
    t.boolean "force_to_redownload_wiki"
    t.string "last_repository_sync_failure"
    t.string "last_wiki_sync_failure"
    t.string "last_repository_verification_failure"
    t.string "last_wiki_verification_failure"
    t.binary "repository_verification_checksum_sha"
    t.binary "wiki_verification_checksum_sha"
    t.boolean "repository_checksum_mismatch", default: false, null: false
    t.boolean "wiki_checksum_mismatch", default: false, null: false
    t.boolean "last_repository_check_failed"
    t.datetime_with_timezone "last_repository_check_at"
    t.datetime_with_timezone "resync_repository_was_scheduled_at"
    t.datetime_with_timezone "resync_wiki_was_scheduled_at"
    t.boolean "repository_missing_on_primary"
    t.boolean "wiki_missing_on_primary"
    t.integer "repository_verification_retry_count"
    t.integer "wiki_verification_retry_count"
    t.datetime_with_timezone "last_repository_verification_ran_at"
    t.datetime_with_timezone "last_wiki_verification_ran_at"
    t.binary "repository_verification_checksum_mismatched"
    t.binary "wiki_verification_checksum_mismatched"
    t.boolean "primary_repository_checksummed", default: false, null: false
    t.boolean "primary_wiki_checksummed", default: false, null: false
    t.index ["last_repository_successful_sync_at"], name: "idx_project_registry_synced_repositories_partial", where: "((resync_repository = false) AND (repository_retry_count IS NULL) AND (repository_verification_checksum_sha IS NOT NULL))"
    t.index ["last_repository_successful_sync_at"], name: "index_project_registry_on_last_repository_successful_sync_at"
    t.index ["last_repository_synced_at"], name: "index_project_registry_on_last_repository_synced_at"
    t.index ["project_id"], name: "idx_project_registry_on_repo_checksums_and_failure_partial", where: "((repository_verification_checksum_sha IS NULL) AND (last_repository_verification_failure IS NULL))"
    t.index ["project_id"], name: "idx_project_registry_on_repository_failure_partial", where: "(last_repository_verification_failure IS NOT NULL)"
    t.index ["project_id"], name: "idx_project_registry_on_wiki_checksums_and_failure_partial", where: "((wiki_verification_checksum_sha IS NULL) AND (last_wiki_verification_failure IS NULL))"
    t.index ["project_id"], name: "idx_project_registry_on_wiki_failure_partial", where: "(last_wiki_verification_failure IS NOT NULL)"
    t.index ["project_id"], name: "idx_repository_checksum_mismatch", where: "(repository_checksum_mismatch = true)"
    t.index ["project_id"], name: "idx_wiki_checksum_mismatch", where: "(wiki_checksum_mismatch = true)"
    t.index ["project_id"], name: "index_project_registry_on_project_id", unique: true
    t.index ["repository_retry_at"], name: "index_project_registry_on_repository_retry_at"
    t.index ["repository_retry_count"], name: "idx_project_registry_failed_repositories_partial", where: "((repository_retry_count > 0) OR (last_repository_verification_failure IS NOT NULL) OR repository_checksum_mismatch)"
    t.index ["repository_retry_count"], name: "idx_project_registry_pending_repositories_partial", where: "((repository_retry_count IS NULL) AND (last_repository_successful_sync_at IS NOT NULL) AND ((resync_repository = true) OR ((repository_verification_checksum_sha IS NULL) AND (last_repository_verification_failure IS NULL))))"
    t.index ["repository_verification_checksum_sha"], name: "idx_project_registry_on_repository_checksum_sha_partial", where: "(repository_verification_checksum_sha IS NULL)"
    t.index ["resync_repository"], name: "index_project_registry_on_resync_repository"
    t.index ["resync_wiki"], name: "index_project_registry_on_resync_wiki"
    t.index ["wiki_retry_at"], name: "index_project_registry_on_wiki_retry_at"
    t.index ["wiki_verification_checksum_sha"], name: "idx_project_registry_on_wiki_checksum_sha_partial", where: "(wiki_verification_checksum_sha IS NULL)"
  end

  create_table "secondary_usage_data", force: :cascade do |t|
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.jsonb "payload", default: {}, null: false
  end

  create_table "snippet_repository_registry", force: :cascade do |t|
    t.datetime_with_timezone "retry_at"
    t.datetime_with_timezone "last_synced_at"
    t.datetime_with_timezone "created_at", null: false
    t.bigint "snippet_repository_id", null: false
    t.integer "state", limit: 2, default: 0, null: false
    t.integer "retry_count", limit: 2, default: 0
    t.text "last_sync_failure"
    t.boolean "force_to_redownload"
    t.boolean "missing_on_primary"
    t.datetime_with_timezone "verification_started_at"
    t.datetime_with_timezone "verified_at"
    t.datetime_with_timezone "verification_retry_at"
    t.integer "verification_retry_count"
    t.integer "verification_state", limit: 2, default: 0, null: false
    t.boolean "checksum_mismatch"
    t.binary "verification_checksum"
    t.binary "verification_checksum_mismatched"
    t.string "verification_failure", limit: 255
    t.index ["retry_at"], name: "index_snippet_repository_registry_on_retry_at"
    t.index ["snippet_repository_id"], name: "index_snippet_repository_registry_on_snippet_repository_id", unique: true
    t.index ["state"], name: "index_snippet_repository_registry_on_state"
    t.index ["verification_retry_at"], name: "snippet_repository_registry_failed_verification", order: "NULLS FIRST", where: "((state = 2) AND (verification_state = 3))"
    t.index ["verification_state"], name: "snippet_repository_registry_needs_verification", where: "((state = 2) AND (verification_state = ANY (ARRAY[0, 3])))"
    t.index ["verified_at"], name: "snippet_repository_registry_pending_verification", order: "NULLS FIRST", where: "((state = 2) AND (verification_state = 0))"
  end

  create_table "terraform_state_version_registry", force: :cascade do |t|
    t.bigint "terraform_state_version_id", null: false
    t.integer "state", limit: 2, default: 0, null: false
    t.integer "retry_count", limit: 2, default: 0, null: false
    t.datetime_with_timezone "retry_at"
    t.datetime_with_timezone "last_synced_at"
    t.datetime_with_timezone "created_at", null: false
    t.text "last_sync_failure"
    t.datetime_with_timezone "verification_started_at"
    t.datetime_with_timezone "verified_at"
    t.datetime_with_timezone "verification_retry_at"
    t.integer "verification_retry_count", default: 0
    t.integer "verification_state", limit: 2, default: 0, null: false
    t.boolean "checksum_mismatch", default: false, null: false
    t.binary "verification_checksum"
    t.binary "verification_checksum_mismatched"
    t.string "verification_failure", limit: 255
    t.index ["retry_at"], name: "index_terraform_state_version_registry_on_retry_at"
    t.index ["state"], name: "index_terraform_state_version_registry_on_state"
    t.index ["terraform_state_version_id"], name: "index_terraform_state_version_registry_on_t_state_version_id", unique: true
    t.index ["terraform_state_version_id"], name: "index_tf_state_versions_registry_tf_state_versions_id_unique", unique: true
    t.index ["verification_retry_at"], name: "terraform_state_version_registry_failed_verification", order: "NULLS FIRST", where: "((state = 2) AND (verification_state = 3))"
    t.index ["verification_state"], name: "terraform_state_version_registry_needs_verification", where: "((state = 2) AND (verification_state = ANY (ARRAY[0, 3])))"
    t.index ["verified_at"], name: "terraform_state_version_registry_pending_verification", order: "NULLS FIRST", where: "((state = 2) AND (verification_state = 0))"
  end

end
