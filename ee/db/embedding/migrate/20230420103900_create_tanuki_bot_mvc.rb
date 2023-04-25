# frozen_string_literal: true

class CreateTanukiBotMvc < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    create_table :tanuki_bot_mvc do |t|
      t.timestamps_with_timezone null: false
      t.vector :embedding, limit: 1536, null: false
      t.text :url, null: false, limit: 2048
      t.text :content, null: false, limit: 32768
      t.jsonb :metadata, null: false
      t.text :chroma_id, index: { unique: true }, limit: 512
    end
  end

  def down
    drop_table :tanuki_bot_mvc
  end
end
