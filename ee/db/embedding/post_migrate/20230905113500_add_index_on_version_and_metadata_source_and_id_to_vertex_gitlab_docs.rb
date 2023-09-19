# frozen_string_literal: true

class AddIndexOnVersionAndMetadataSourceAndIdToVertexGitlabDocs < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_vertex_gitlab_docs_on_version_and_metadata_source_and_id'

  disable_ddl_transaction!

  def up
    return if index_exists_by_name?(:vertex_gitlab_docs, INDEX_NAME)

    disable_statement_timeout do
      execute <<~SQL
      CREATE INDEX CONCURRENTLY #{INDEX_NAME}
      ON vertex_gitlab_docs
      USING BTREE (version, (metadata->>'source'), id)
      SQL
    end
  end

  def down
    remove_concurrent_index_by_name :vertex_gitlab_docs, INDEX_NAME
  end
end
