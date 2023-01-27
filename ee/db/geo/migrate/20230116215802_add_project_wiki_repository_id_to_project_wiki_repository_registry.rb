# frozen_string_literal: true

class AddProjectWikiRepositoryIdToProjectWikiRepositoryRegistry < Gitlab::Database::Migration[2.1]
  def up
    add_column :project_wiki_repository_registry, :project_wiki_repository_id, :bigint
  end

  def down
    remove_column :project_wiki_repository_registry, :project_wiki_repository_id
  end
end
