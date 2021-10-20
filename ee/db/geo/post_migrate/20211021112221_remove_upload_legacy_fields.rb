# frozen_string_literal: true

class RemoveUploadLegacyFields < Gitlab::Database::Migration[1.0]
  def change
    remove_column :file_registry, :file_type, :string, null: false
    remove_column :file_registry, :success, :boolean, null: false
    remove_column :file_registry, :bytes, :integer
    remove_column :file_registry, :sha256, :string
  end
end
