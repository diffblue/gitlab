# frozen_string_literal: true

class AddDebugTraceToCiBuildsMetadata < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  DOWNTIME = false

  def change
    add_column :p_ci_builds_metadata, :debug_trace, :boolean, null: false, default: false
  end
end
