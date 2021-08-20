# frozen_string_literal: true

class AddVerificationToMergeRequestDiffRegistry < ActiveRecord::Migration[6.0]
  REGISTRY = :merge_request_diff_registry

  def up
    add_column_unless_exists :verification_started_at, :datetime_with_timezone
    add_column_unless_exists :verified_at, :datetime_with_timezone
    add_column_unless_exists :verification_retry_at, :datetime_with_timezone
    add_column_unless_exists :verification_retry_count, :integer
    add_column_unless_exists :verification_state, :integer, limit: 2, default: 0, null: false
    add_column_unless_exists :checksum_mismatch, :boolean
    add_column_unless_exists :verification_checksum, :binary
    add_column_unless_exists :verification_checksum_mismatched, :binary
    add_column_unless_exists :verification_failure, :string, limit: 255 # rubocop:disable Migration/PreventStrings because https://gitlab.com/gitlab-org/gitlab/-/issues/323806
  end

  def add_column_unless_exists(column_name, type, **options)
    return if column_exists?(:merge_request_diff_registry, column_name)

    add_column REGISTRY, column_name, type, **options
  end

  def down
    # no-op
  end
end
