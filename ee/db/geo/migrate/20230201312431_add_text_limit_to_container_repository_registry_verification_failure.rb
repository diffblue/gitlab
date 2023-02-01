# frozen_string_literal: true

class AddTextLimitToContainerRepositoryRegistryVerificationFailure < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :container_repository_registry, :verification_failure, 255
  end

  def down
    remove_text_limit :container_repository_registry, :verification_failure
  end
end
