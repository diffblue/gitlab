# frozen_string_literal: true

class TruncateContainerRepositoryRegistry2 < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    execute('TRUNCATE TABLE container_repository_registry')
  end

  def down
    # noop
  end
end
