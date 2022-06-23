# frozen_string_literal: true

class AddUniqueProjectDownloadLimitSettingsToNamespaceSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :namespace_settings, :unique_project_download_limit, :smallint,
      default: 0, null: false
    add_column :namespace_settings, :unique_project_download_limit_interval, :integer,
      default: 0, null: false
  end
end
