# frozen_string_literal: true

class CreateDependencyProxyManifestRegistry < Gitlab::Database::Migration[2.0]
  def change
    create_table :dependency_proxy_manifest_registry, id: :bigserial, force: :cascade do |t|
      t.bigint :dependency_proxy_manifest_id, null: false
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
      t.binary :verification_checksum
      t.binary :verification_checksum_mismatched
      t.text :verification_failure, limit: 255
      t.text :last_sync_failure, limit: 255

      t.index :dependency_proxy_manifest_id, name: :index_manifest_registry_on_manifest_id, unique: true
      t.index :retry_at
      t.index :state
      # To optimize performance of DependencyProxyManifestRegistry.verification_failed_batch
      t.index :verification_retry_at,
        name: :dependency_proxy_manifest_registry_failed_verification,
        order: "NULLS FIRST", where: "((state = 2) AND (verification_state = 3))"
      # To optimize performance of DependencyProxyManifestRegistry.needs_verification_count
      t.index :verification_state,
        name: :dependency_proxy_manifest_registry_needs_verification,
        where: "((state = 2) AND (verification_state = ANY (ARRAY[0, 3])))"
      # To optimize performance of DependencyProxyManifestRegistry.verification_pending_batch
      t.index :verified_at,
        name: :dependency_proxy_manifest_registry_pending_verification,
        order: "NULLS FIRST",
        where: "((state = 2) AND (verification_state = 0))"
    end
  end
end
