# frozen_string_literal: true

class AddIndexOnVersionWhereEmbeddingIsNullToTanukiBotMvc < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_tanuki_bot_mvc_on_version_where_embedding_is_null'

  disable_ddl_transaction!

  def up
    add_concurrent_index :tanuki_bot_mvc, :version, where: 'embedding IS NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :tanuki_bot_mvc, INDEX_NAME
  end
end
