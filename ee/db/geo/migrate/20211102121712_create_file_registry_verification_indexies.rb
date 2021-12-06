# frozen_string_literal: true

class CreateFileRegistryVerificationIndexies < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_concurrent_index :file_registry, :verification_retry_at, name: :file_registry_failed_verification, order: "NULLS FIRST", where: "((state = 2) AND (verification_state = 3))"
    # To optimize performance of UploadRegistry.needs_verification_count
    add_concurrent_index :file_registry, :verification_state, name: :file_registry_needs_verification, where: "((state = 2)  AND (verification_state = ANY (ARRAY[0, 3])))"
    # To optimize performance of UploadRegistry.verification_pending_batch
    add_concurrent_index :file_registry, :verified_at, name: :file_registry_pending_verification, order: "NULLS FIRST", where: "((state = 2) AND (verification_state = 0))"
  end

  def down
    remove_concurrent_index :file_registry, :verification_retry_at, name: :file_registry_failed_verification
    remove_concurrent_index :file_registry, :verification_state, name: :file_registry_needs_verification
    remove_concurrent_index :file_registry, :verified_at, name: :file_registry_pending_verification
  end
end
