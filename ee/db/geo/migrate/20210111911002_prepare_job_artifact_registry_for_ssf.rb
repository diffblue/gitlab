# frozen_string_literal: true

class PrepareJobArtifactRegistryForSsf < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def change
    change_column_default :job_artifact_registry, :retry_count, from: nil, to: 0
    add_column :job_artifact_registry, :last_synced_at, :datetime_with_timezone
    add_column :job_artifact_registry, :verified_at, :datetime_with_timezone
    add_column :job_artifact_registry, :verification_started_at, :datetime_with_timezone
    add_column :job_artifact_registry, :verification_retry_at, :datetime_with_timezone
    add_column :job_artifact_registry, :state, :integer, null: false, limit: 2, default: 0
    add_column :job_artifact_registry, :verification_state, :integer, default: 0, null: false, limit: 2
    add_column :job_artifact_registry, :verification_retry_count, :integer, default: 0, limit: 2, null: false
    add_column :job_artifact_registry, :verification_checksum, :binary
    add_column :job_artifact_registry, :verification_checksum_mismatched, :binary
    add_column :job_artifact_registry, :checksum_mismatch, :boolean, default: false, null: false
    add_column :job_artifact_registry, :verification_failure, :string, limit: 255 # rubocop:disable Migration/PreventStrings see https://gitlab.com/gitlab-org/gitlab/-/issues/323806
    add_column :job_artifact_registry, :last_sync_failure, :string, limit: 255 # rubocop:disable Migration/PreventStrings see https://gitlab.com/gitlab-org/gitlab/-/issues/323806
  end
end
