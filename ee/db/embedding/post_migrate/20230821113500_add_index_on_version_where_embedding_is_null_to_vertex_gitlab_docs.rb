# frozen_string_literal: true

class AddIndexOnVersionWhereEmbeddingIsNullToVertexGitlabDocs < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_vertex_gitlab_docs_on_version_where_embedding_is_null'

  disable_ddl_transaction!

  def up
    add_concurrent_index :vertex_gitlab_docs, :version, where: 'embedding IS NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :vertex_gitlab_docs, INDEX_NAME
  end
end
