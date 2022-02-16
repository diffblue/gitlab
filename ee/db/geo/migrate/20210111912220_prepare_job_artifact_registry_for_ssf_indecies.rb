# frozen_string_literal: true

class PrepareJobArtifactRegistryForSsfIndecies < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_concurrent_index :job_artifact_registry, :verification_retry_at, name: :job_artifact_registry_failed_verification, order: "NULLS FIRST", where: "((state = 2) AND (verification_state = 3))"
    add_concurrent_index :job_artifact_registry, :verification_state, name: :job_artifact_registry_needs_verification, where: "((state = 2)  AND (verification_state = ANY (ARRAY[0, 3])))"
    add_concurrent_index :job_artifact_registry, :verified_at, name: :job_artifact_registry_pending_verification, order: "NULLS FIRST", where: "((state = 2) AND (verification_state = 0))"
  end

  def down
    remove_concurrent_index :job_artifact_registry, :verification_retry_at, name: :job_artifact_registry_failed_verification
    remove_concurrent_index :job_artifact_registry, :verification_state, name: :job_artifact_registry_needs_verification
    remove_concurrent_index :job_artifact_registry, :verified_at, name: :job_artifact_registry_pending_verification
  end
end
