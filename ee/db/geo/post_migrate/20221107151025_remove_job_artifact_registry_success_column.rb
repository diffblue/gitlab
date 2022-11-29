# frozen_string_literal: true

class RemoveJobArtifactRegistrySuccessColumn < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    remove_column :job_artifact_registry, :success
  end

  def down
    add_column :job_artifact_registry, :success, :boolean unless column_exists?(:job_artifact_registry, :success)

    add_concurrent_index(:job_artifact_registry, :success)
  end
end
