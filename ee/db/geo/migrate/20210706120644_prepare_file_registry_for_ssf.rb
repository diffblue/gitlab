# frozen_string_literal: true

class PrepareFileRegistryForSsf < ActiveRecord::Migration[6.1]
  def change
    change_column_default :file_registry, :retry_count, from: nil, to: 0
    add_column :file_registry, :state, :integer, null: false, limit: 2, default: 0
    add_column :file_registry, :last_synced_at, :datetime_with_timezone
    add_column :file_registry, :last_sync_failure, :string, limit: 255 # rubocop:disable Migration/PreventStrings see https://gitlab.com/gitlab-org/gitlab/-/issues/323806
  end
end
