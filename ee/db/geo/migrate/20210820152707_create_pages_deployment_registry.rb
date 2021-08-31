# frozen_string_literal: true

class CreatePagesDeploymentRegistry < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def change
    create_table :pages_deployment_registry, id: :bigserial, force: :cascade do |t|
      t.bigint :pages_deployment_id, null: false
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :last_synced_at
      t.datetime_with_timezone :retry_at
      t.integer :state, default: 0, null: false, limit: 2
      t.integer :retry_count, default: 0, limit: 2, null: false
      t.string :last_sync_failure, limit: 255 # rubocop:disable Migration/PreventStrings see https://gitlab.com/gitlab-org/gitlab/-/issues/323806

      t.index :pages_deployment_id, name: :index_pages_deployment_registry_on_pages_deployment_id, unique: true
      t.index :retry_at
      t.index :state
    end
  end
end
