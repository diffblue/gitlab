# frozen_string_literal: true

class CreateContainerRepositoryRegistryVerificationIndexies < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_index :container_repository_registry,
      :verification_retry_at,
      name: :container_repository_registry_failed_verification,
      order: 'NULLS FIRST', where: 'verification_state = 3'
    add_concurrent_index :container_repository_registry,
      :verification_state,
      name: :container_repository_registry_needs_verification,
      where: "verification_state = ANY (ARRAY[0, 3])"
    add_concurrent_index :container_repository_registry,
      :verified_at,
      name: :container_repository_registry_pending_verification,
      order: 'NULLS FIRST', where: 'verification_state = 0'
  end

  def down
    remove_concurrent_index :container_repository_registry,
      :verification_retry_at,
      name: :container_repository_registry_failed_verification
    remove_concurrent_index :container_repository_registry,
      :verification_state,
      name: :container_repository_registry_needs_verification
    remove_concurrent_index :container_repository_registry,
      :verified_at,
      name: :container_repository_registry_pending_verification
  end
end
