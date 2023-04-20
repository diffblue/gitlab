# frozen_string_literal: true

class CreateVectorExtension < Gitlab::Database::Migration[2.1]
  EXTENSION_NAME = 'vector'

  def up
    create_extension EXTENSION_NAME
  end

  def down
    drop_extension EXTENSION_NAME
  end
end
