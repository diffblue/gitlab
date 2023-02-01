# frozen_string_literal: true

class PrepareContainerRepositoryRegistryForVerification < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_column :container_repository_registry, :verified_at, :datetime_with_timezone
    add_column :container_repository_registry, :verification_started_at, :datetime_with_timezone
    add_column :container_repository_registry, :verification_retry_at, :datetime_with_timezone
    add_column :container_repository_registry, :verification_state, :integer, default: 0, null: false, limit: 2
    add_column :container_repository_registry, :verification_retry_count, :integer, default: 0, limit: 2, null: false
    add_column :container_repository_registry, :verification_checksum, :binary
    add_column :container_repository_registry, :verification_checksum_mismatched, :binary
    add_column :container_repository_registry, :checksum_mismatch, :boolean, default: false, null: false

    # rubocop:disable Migration/AddLimitToTextColumns
    # limit is added in a separate migration
    add_column :container_repository_registry, :verification_failure, :text
    # rubocop:enable Migration/AddLimitToTextColumns
  end

  def down
    remove_column :container_repository_registry, :verified_at
    remove_column :container_repository_registry, :verification_started_at
    remove_column :container_repository_registry, :verification_retry_at
    remove_column :container_repository_registry, :verification_state
    remove_column :container_repository_registry, :verification_retry_count
    remove_column :container_repository_registry, :verification_checksum
    remove_column :container_repository_registry, :verification_checksum_mismatched
    remove_column :container_repository_registry, :checksum_mismatch
    remove_column :container_repository_registry, :verification_failure
  end
end
