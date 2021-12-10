# frozen_string_literal: true

class AddVerificationToLfsObjectRegistry < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20211124000001_add_text_limit_to_lfs_object_registry_verification_failure.rb
  def change
    add_column :lfs_object_registry, :verification_started_at, :datetime_with_timezone
    add_column :lfs_object_registry, :verified_at, :datetime_with_timezone
    add_column :lfs_object_registry, :verification_retry_at, :datetime_with_timezone
    add_column :lfs_object_registry, :verification_retry_count, :integer, default: 0
    add_column :lfs_object_registry, :verification_state, :integer, limit: 2, default: 0, null: false
    add_column :lfs_object_registry, :checksum_mismatch, :boolean, default: false, null: false
    add_column :lfs_object_registry, :verification_checksum, :binary
    add_column :lfs_object_registry, :verification_checksum_mismatched, :binary
    add_column :lfs_object_registry, :verification_failure, :text
    # rubocop:enable Migration/AddLimitToTextColumns
  end
end
