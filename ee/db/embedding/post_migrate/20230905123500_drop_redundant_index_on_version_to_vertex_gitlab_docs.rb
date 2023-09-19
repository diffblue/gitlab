# frozen_string_literal: true

class DropRedundantIndexOnVersionToVertexGitlabDocs < Gitlab::Database::Migration[2.1]
  # this index is covered by the new index_vertex_gitlab_docs_on_version_and_metadata_source index
  INDEX_NAME = 'index_vertex_gitlab_docs_on_version'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :vertex_gitlab_docs, INDEX_NAME
  end

  def down
    add_concurrent_index :vertex_gitlab_docs, :version, name: INDEX_NAME
  end
end
