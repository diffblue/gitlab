# frozen_string_literal: true

class CreateDesignManagementRepositoryRegistry < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_design_repo_registry_on_design_repo_id'

  def change
    create_table :design_management_repository_registry, id: :bigserial, force: :cascade do |t|
      t.bigint :design_management_repository_id, null: false
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :last_synced_at
      t.datetime_with_timezone :retry_at
      t.datetime_with_timezone :verified_at
      t.datetime_with_timezone :verification_started_at
      t.datetime_with_timezone :verification_retry_at
      t.integer :state, default: 0, null: false, limit: 2
      t.integer :verification_state, default: 0, null: false, limit: 2
      t.integer :retry_count, default: 0, limit: 2, null: false
      t.integer :verification_retry_count, default: 0, limit: 2, null: false
      t.boolean :checksum_mismatch, default: false, null: false
      t.boolean :force_to_redownload, default: false, null: false
      t.boolean :missing_on_primary, default: false, null: false
      t.binary :verification_checksum
      t.binary :verification_checksum_mismatched
      t.text :verification_failure, limit: 255
      t.text :last_sync_failure, limit: 255

      t.index :design_management_repository_id, name: INDEX_NAME, unique: true
      t.index :retry_at
      t.index :state
      # To optimize performance of DesignManagementRepositoryRegistry.verification_failed_batch
      t.index :verification_retry_at,
        name: :design_management_repository_registry_failed_verification,
        order: "NULLS FIRST",
        where: "((state = 2) AND (verification_state = 3))"
      # To optimize performance of DesignManagementRepositoryRegistry.needs_verification_count
      t.index :verification_state,
        name: :design_management_repository_registry_needs_verification,
        where: "((state = 2) AND (verification_state = ANY (ARRAY[0, 3])))"
      # To optimize performance of DesignManagementRepositoryRegistry.verification_pending_batch
      t.index :verified_at,
        name: :design_management_repository_registry_pending_verification,
        order: "NULLS FIRST",
        where: "((state = 2) AND (verification_state = 0))"
    end
  end
end
