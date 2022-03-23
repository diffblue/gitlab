# frozen_string_literal: true

class CreateFileRegistry < ActiveRecord::Migration[4.2]
  # rubocop:disable Migration/PreventStrings
  def change
    create_table :file_registry do |t|
      t.string  :file_type, null: false
      t.integer :file_id, null: false
      t.integer :bytes
      t.string  :sha256

      t.datetime :created_at, null: false # rubocop:disable Migration/Datetime
    end

    add_index :file_registry, :file_type
    add_index :file_registry, [:file_type, :file_id], unique: true
  end
  # rubocop:enable Migration/PreventStrings
end
