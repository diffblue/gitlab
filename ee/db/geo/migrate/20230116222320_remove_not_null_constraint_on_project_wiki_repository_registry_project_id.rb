# frozen_string_literal: true

class RemoveNotNullConstraintOnProjectWikiRepositoryRegistryProjectId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    change_column_null :project_wiki_repository_registry, :project_id, true
  end

  def down
    change_column_null :project_wiki_repository_registry, :project_id, false
  end
end
