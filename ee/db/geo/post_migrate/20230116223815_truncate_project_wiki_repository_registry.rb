# frozen_string_literal: true

class TruncateProjectWikiRepositoryRegistry < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    execute('TRUNCATE TABLE project_wiki_repository_registry')
  end

  def down
    # no-op
  end
end
