# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class TestBatchMigrationForCr < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  disable_ddl_transaction!

  class ClusterEnabledGrant < MigrationRecord
    self.table_name = 'cluster_enabled_grants'
  end

  def up
    Group
      .select(:id)
      .where(id:
          Group.joins(:cluster_groups)
               .select('DISTINCT(traversal_ids[1])')
            )
      .each_batch(of: 1000) do |batch|
      values = batch.map do |namespace|
        "(#{namespace.id}, NOW())"
      end.join(',')

      bulk_insert_query = <<-SQL
        INSERT INTO cluster_enabled_grants (namespace_id)
        VALUES #{values}
        ON CONFLICT (namespace_id) DO NOTHING;
      SQL

      connection.execute(bulk_insert_query)
    end

    Namespace
      .select(:id)
      .where(id:
        Namespace.joins(projects: :cluster_project)
                 .select('DISTINCT(traversal_ids[1])')
            )
      .each_batch(of: 1000) do |batch|
      values = batch.map do |namespace|
        "(#{namespace.id}, NOW())"
      end.join(',')

      bulk_insert_query = <<-SQL
        INSERT INTO cluster_enabled_grants (namespace_id, created_at)
        VALUES #{values}
        ON CONFLICT (namespace_id) DO NOTHING;
      SQL

      connection.execute(bulk_insert_query)
    end
  end

  def down
    ClusterEnabledGrant.delete_all
  end
end
