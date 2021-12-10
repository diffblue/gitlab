# frozen_string_literal: true

class AddTextLimitToLfsObjectRegistryVerificationFailure < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :lfs_object_registry, :verification_failure, 255
  end

  def down
    remove_text_limit :lfs_object_registry, :verification_failure
  end
end
