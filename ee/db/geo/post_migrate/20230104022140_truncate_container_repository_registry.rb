# frozen_string_literal: true

class TruncateContainerRepositoryRegistry < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    execute('TRUNCATE TABLE container_repository_registry')
  end

  def down
    # noop
  end
end
