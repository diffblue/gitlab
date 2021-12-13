# frozen_string_literal: true

class AddVerificationToPagesDeploymentRegistry < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def change
    add_column :pages_deployment_registry, :verification_started_at, :datetime_with_timezone
    add_column :pages_deployment_registry, :verified_at, :datetime_with_timezone
    add_column :pages_deployment_registry, :verification_retry_at, :datetime_with_timezone
    add_column :pages_deployment_registry, :verification_retry_count, :integer, default: 0, limit: 2, null: false
    add_column :pages_deployment_registry, :verification_state, :integer, limit: 2, default: 0, null: false
    add_column :pages_deployment_registry, :checksum_mismatch, :boolean, default: false, null: false
    add_column :pages_deployment_registry, :verification_checksum, :binary
    add_column :pages_deployment_registry, :verification_checksum_mismatched, :binary
    # limit is added in 20211207175940_add_text_limit_to_pages_deployment_registry_verification_failure.rb
    add_column :pages_deployment_registry, :verification_failure, :text # rubocop:disable Migration/AddLimitToTextColumns
  end
end
