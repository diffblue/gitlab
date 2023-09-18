# frozen_string_literal: true

class DropDesignRegistry < Gitlab::Database::Migration[2.1]
  def up
    drop_table :design_registry
  end

  def down
    create_table :design_registry, id: :serial, force: :cascade do |t|
      t.integer :project_id, null: false
      t.string :state, limit: 20
      t.integer :retry_count, default: 0
      t.string :last_sync_failure
      t.boolean :force_to_redownload
      t.boolean :missing_on_primary
      t.datetime_with_timezone :retry_at
      t.datetime_with_timezone :last_synced_at
      t.datetime_with_timezone :created_at, null: false

      t.index :project_id, name: :index_design_registry_on_project_id, using: :btree
      t.index :retry_at, name: :index_design_registry_on_retry_at, using: :btree
      t.index :state, name: :index_design_registry_on_state, using: :btree
    end
  end
end
