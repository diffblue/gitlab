# frozen_string_literal: true

class AddTasksToBeDoneToMembers < Gitlab::Database::Migration[1.0]
  def change
    add_column :members, :tasks_to_be_done, :integer, array: true, null: true
    add_column :members, :tasks_project_id, :bigint, null: true
  end
end
