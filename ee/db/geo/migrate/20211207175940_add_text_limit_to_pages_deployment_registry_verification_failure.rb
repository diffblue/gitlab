# frozen_string_literal: true

class AddTextLimitToPagesDeploymentRegistryVerificationFailure < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :pages_deployment_registry, :verification_failure, 255
  end

  def down
    remove_text_limit :pages_deployment_registry, :verification_failure
  end
end
