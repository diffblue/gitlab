# frozen_string_literal: true

class AddHiddenToProjects < Gitlab::Database::Migration[1.0]
  DOWNTIME = false
  INDEX_NAME = 'index_projects_on_hidden'

  disable_ddl_transaction!

  def up
    add_column :projects, :hidden, :boolean, default: false # rubocop: disable Migration/AddColumnsToWideTables
    add_concurrent_index :projects, :hidden, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :projects, INDEX_NAME
    remove_column :projects, :hidden
  end
end
