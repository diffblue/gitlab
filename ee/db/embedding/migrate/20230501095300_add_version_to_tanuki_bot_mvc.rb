# frozen_string_literal: true

class AddVersionToTanukiBotMvc < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    add_column :tanuki_bot_mvc, :version, :integer, default: 0, null: false
  end

  def down
    remove_column :tanuki_bot_mvc, :version
  end
end
