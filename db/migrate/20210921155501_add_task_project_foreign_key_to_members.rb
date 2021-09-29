# frozen_string_literal: true

class AddTaskProjectForeignKeyToMembers < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_members_on_tasks_project_id'

  def up
    add_concurrent_index :members, :tasks_project_id, name: INDEX_NAME
    add_concurrent_foreign_key :members, :projects, column: :tasks_project_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :members, column: :tasks_project_id
    end

    remove_concurrent_index_by_name :members, name: INDEX_NAME
  end
end
