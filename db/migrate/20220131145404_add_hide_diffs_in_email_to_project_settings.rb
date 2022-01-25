# frozen_string_literal: true

class AddHideDiffsInEmailToProjectSettings < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :project_settings, :hide_diffs_in_email, :boolean, default: false, null: false
  end
end
