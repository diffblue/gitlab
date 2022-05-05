# frozen_string_literal: true

class AddAllowStaleRunnerPruningIndexToNamespaceCiCdSettings < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_namespace_ci_cd_settings_on_stale_runner_pruning_enabled'

  disable_ddl_transaction!

  def up
    add_concurrent_index :namespace_ci_cd_settings,
      :allow_stale_runner_pruning,
      where: '(allow_stale_runner_pruning = true)',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :namespace_ci_cd_settings, INDEX_NAME
  end
end
