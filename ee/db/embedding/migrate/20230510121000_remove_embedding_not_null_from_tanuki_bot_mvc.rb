# frozen_string_literal: true

class RemoveEmbeddingNotNullFromTanukiBotMvc < Gitlab::Database::Migration[2.1]
  def up
    change_column_null :tanuki_bot_mvc, :embedding, true
  end

  def down
    # no-op : can't go back to `NULL` without first dropping the `NOT NULL` constraint
  end
end
