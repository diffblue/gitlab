# frozen_string_literal: true

class AddMissingOnPrimaryToJobArtifactRegistry < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :job_artifact_registry, :missing_on_primary, :boolean, default: false, allow_null: false
  end

  def down
    remove_column :job_artifact_registry, :missing_on_primary if column_exists?(:job_artifact_registry, :missing_on_primary)
  end
end
