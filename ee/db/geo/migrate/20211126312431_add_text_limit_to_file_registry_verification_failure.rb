# frozen_string_literal: true

class AddTextLimitToFileRegistryVerificationFailure < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :file_registry, :verification_failure, 256
  end

  def down
    remove_text_limit :file_registry, :verification_failure
  end
end
