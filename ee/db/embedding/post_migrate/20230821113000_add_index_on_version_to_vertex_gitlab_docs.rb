# frozen_string_literal: true

class AddIndexOnVersionToVertexGitlabDocs < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_vertex_gitlab_docs_on_version'

  disable_ddl_transaction!

  def up
    add_concurrent_index :vertex_gitlab_docs, :version, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :vertex_gitlab_docs, INDEX_NAME
  end
end
