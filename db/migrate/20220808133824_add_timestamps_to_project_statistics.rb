# frozen_string_literal: true

class AddTimestampsToProjectStatistics < Gitlab::Database::Migration[2.0]
  def up
    add_timestamps_with_timezone(:project_statistics, null: false, default: -> { 'NOW()' })

    change_column_default :project_statistics, :created_at, nil
    change_column_default :project_statistics, :updated_at, nil
  end

  def down
    remove_timestamps(:project_statistics)
  end
end
