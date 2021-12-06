# frozen_string_literal: true

class PrepareFileRegistryForVerification < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_column :file_registry, :verified_at, :datetime_with_timezone
    add_column :file_registry, :verification_started_at, :datetime_with_timezone
    add_column :file_registry, :verification_retry_at, :datetime_with_timezone
    add_column :file_registry, :verification_state, :integer, default: 0, null: false, limit: 2
    add_column :file_registry, :verification_retry_count, :integer, default: 0, limit: 2, null: false
    add_column :file_registry, :verification_checksum, :binary
    add_column :file_registry, :verification_checksum_mismatched, :binary
    add_column :file_registry, :checksum_mismatch, :boolean, default: false, null: false

    # rubocop:disable Migration/AddLimitToTextColumns
    # limit is added in 20211126312431_add_text_limit_to_file_registry_verification_failure.rb
    add_column :file_registry, :verification_failure, :text
    # rubocop:enable Migration/AddLimitToTextColumns
  end

  def down
    remove_column :file_registry, :verified_at
    remove_column :file_registry, :verification_started_at
    remove_column :file_registry, :verification_retry_at
    remove_column :file_registry, :verification_state
    remove_column :file_registry, :verification_retry_count
    remove_column :file_registry, :verification_checksum
    remove_column :file_registry, :verification_checksum_mismatched
    remove_column :file_registry, :checksum_mismatch
    remove_column :file_registry, :verification_failure
  end
end
