# frozen_string_literal: true

class AddNeedsResyncToProjectRegistry < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column(:project_registry, :resync_repository, :boolean, default: true)
    add_column(:project_registry, :resync_wiki, :boolean, default: true)
  end

  def down
    remove_columns :project_registry, :resync_repository, :resync_wiki
  end
end
