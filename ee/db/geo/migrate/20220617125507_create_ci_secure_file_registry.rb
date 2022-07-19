# frozen_string_literal: true
# rubocop:disable Layout/LineLength

class CreateCiSecureFileRegistry < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    ActiveRecord::Base.transaction do
      create_table :ci_secure_file_registry, id: :bigserial, force: :cascade do |t|
        t.bigint :ci_secure_file_id, null: false
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

        t.index :ci_secure_file_id, name: :index_ci_secure_file_registry_on_ci_secure_file_id, unique: true
        t.index :retry_at
        t.index :state
        # To optimize performance of CiSecureFileRegistry.verification_failed_batch
        t.index :verification_retry_at, name: :ci_secure_file_registry_failed_verification, order: "NULLS FIRST", where: "((state = 2) AND (verification_state = 3))"
        # To optimize performance of CiSecureFileRegistry.needs_verification_count
        t.index :verification_state, name:  :ci_secure_file_registry_needs_verification, where: "((state = 2)  AND (verification_state = ANY (ARRAY[0, 3])))"
        # To optimize performance of CiSecureFileRegistry.verification_pending_batch
        t.index :verified_at, name: :ci_secure_file_registry_pending_verification, order: "NULLS FIRST", where: "((state = 2) AND (verification_state = 0))"
      end
    end
  end

  def down
    drop_table :ci_secure_file_registry
  end
end
# rubocop:enable Layout/LineLength
