# frozen_string_literal: true

class AddIndexToProjectWikiRepositoryRegistry < Gitlab::Database::Migration[2.1]
  INDEX_NAME = "idx_project_wiki_repository_registry_project_wiki_repository_id"

  disable_ddl_transaction!

  def up
    add_concurrent_index :project_wiki_repository_registry, :project_wiki_repository_id, name: INDEX_NAME, unique: true
  end

  def down
    remove_concurrent_index_by_name :project_wiki_repository_registry, name: INDEX_NAME
  end
end
