# frozen_string_literal: true

class AddWorkItemParentChildTable < Gitlab::Database::Migration[2.0]
  def up
    create_table :work_item_parent_links do |t|
      t.references :work_item,
                   index: true,
                   unique: true,
                   foreign_key: { to_table: :issues, on_delete: :cascade },
                   null: false
      t.references :work_item_parent,
                   index: true,
                   foreign_key: { to_table: :issues, on_delete: :cascade },
                   null: false
      t.integer :relative_position
      t.timestamps_with_timezone null: false
    end
  end

  def down
    drop_table :work_item_parent_links
  end
end
