# frozen_string_literal: true

class AddOperationsAccessLevelsToProjectFeature < Gitlab::Database::Migration[2.0]
  OPERATIONS_DEFAULT_VALUE = 20

  def up
    add_column :project_features, :monitor_access_level, :integer, null: false, default: OPERATIONS_DEFAULT_VALUE
    add_column :project_features, :infrastructure_access_level, :integer, null: false, default: OPERATIONS_DEFAULT_VALUE
    add_column :project_features, :deployments_access_level, :integer, null: false, default: OPERATIONS_DEFAULT_VALUE
  end

  def down
    remove_column :project_features, :monitor_access_level
    remove_column :project_features, :infrastructure_access_level
    remove_column :project_features, :deployments_access_level
  end
end
