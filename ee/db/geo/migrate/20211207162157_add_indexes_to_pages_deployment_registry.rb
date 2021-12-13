# frozen_string_literal: true

class AddIndexesToPagesDeploymentRegistry < Gitlab::Database::Migration[1.0]
  PAGES_DEPLOYMENT_ID_INDEX_NAME = "index_pages_deployment_registry_on_pages_deployment_id"
  FAILED_VERIFICATION_INDEX_NAME = "pages_deployment_registry_failed_verification"
  NEEDS_VERIFICATION_INDEX_NAME = "pages_deployment_registry_needs_verification"
  PENDING_VERIFICATION_INDEX_NAME = "pages_deployment_registry_pending_verification"

  REGISTRY_TABLE = :pages_deployment_registry

  disable_ddl_transaction!

  def up
    add_concurrent_index REGISTRY_TABLE, :pages_deployment_id, name: PAGES_DEPLOYMENT_ID_INDEX_NAME, unique: true
    add_concurrent_index REGISTRY_TABLE, :verification_retry_at, name: FAILED_VERIFICATION_INDEX_NAME, order: "NULLS FIRST", where: "((state = 2) AND (verification_state = 3))"
    add_concurrent_index REGISTRY_TABLE, :verification_state, name: NEEDS_VERIFICATION_INDEX_NAME, where: "((state = 2) AND (verification_state = ANY (ARRAY[0, 3])))"
    add_concurrent_index REGISTRY_TABLE, :verified_at, name: PENDING_VERIFICATION_INDEX_NAME, order: "NULLS FIRST", where: "((state = 2) AND (verification_state = 0))"
  end

  def down
    remove_concurrent_index_by_name REGISTRY_TABLE, name: PAGES_DEPLOYMENT_ID_INDEX_NAME
    remove_concurrent_index_by_name REGISTRY_TABLE, name: FAILED_VERIFICATION_INDEX_NAME
    remove_concurrent_index_by_name REGISTRY_TABLE, name: NEEDS_VERIFICATION_INDEX_NAME
    remove_concurrent_index_by_name REGISTRY_TABLE, name: PENDING_VERIFICATION_INDEX_NAME
  end
end
