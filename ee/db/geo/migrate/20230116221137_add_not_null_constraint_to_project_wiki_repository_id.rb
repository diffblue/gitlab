# frozen_string_literal: true

class AddNotNullConstraintToProjectWikiRepositoryId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_not_null_constraint :project_wiki_repository_registry, :project_wiki_repository_id, validate: false
  end

  def down
    remove_not_null_constraint :project_wiki_repository_registry, :project_wiki_repository_id
  end
end
