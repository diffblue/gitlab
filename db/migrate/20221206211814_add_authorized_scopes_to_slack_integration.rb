# frozen_string_literal: true

class AddAuthorizedScopesToSlackIntegration < Gitlab::Database::Migration[2.1]
  def up
    create_table :known_slack_api_scopes do |t|
      t.text :name, null: false, limit: 100

      t.index :name, name: 'index_known_slack_api_scopes', unique: true
    end

    create_table :slack_integrations_authorized_scopes do |t|
      references :known_slack_api_scope,
        null: false,
        index: { name: 'index_authorized_scopes_on_scope' },
        foreign_key: {
          to_table: :known_slack_api_scopes,
          on_delete: :cascade
        }

      references :slack_integration,
        null: false,
        index: { name: 'index_authorized_scopes_on_integration' },
        foreign_key: {
          to_table: :slack_integrations,
          on_delete: :cascade
        }

      t.index [:known_slack_api_scope_id, :slack_integration_id],
        unique: true,
        name: 'index_known_slack_api_scopes_on_name_and_integration'
    end
  end

  def down
    drop_table :slack_integrations_authorized_scopes, if_exists: true
    drop_table :known_slack_api_scopes, if_exists: true
  end
end
