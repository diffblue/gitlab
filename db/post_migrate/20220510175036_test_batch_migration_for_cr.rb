# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class TestBatchMigrationForCr < Gitlab::Database::Migration[2.0]
  # When using the methods "add_concurrent_index" or "remove_concurrent_index"
  # you must disable the use of transactions
  # as these methods can not run in an existing transaction.
  # When using "add_concurrent_index" or "remove_concurrent_index" methods make sure
  # that either of them is the _only_ method called in the migration,
  # any other changes should go in a separate migration.
  # This ensures that upon failure _only_ the index creation or removing fails
  # and can be retried or reverted easily.
  #
  # To disable transactions uncomment the following line and remove these
  # comments:
  disable_ddl_transaction!
  #
  # Configure the `gitlab_schema` to perform data manipulation (DML).
  # Visit: https://docs.gitlab.com/ee/development/database/migrations_for_multiple_databases.html
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    root_ancestor_set = Set[]

    Group.where(id:
                  Group.joins(:cluster_groups)
                       .select('DISTINCT(traversal_ids[1])')
               ).find_each(batch_size: 1000) do |namespace|
      root_ancestor_set.add(namespace)
    end

    Namespace.where(id:
                      Namespace.joins(projects: :cluster_project)
                               .select('DISTINCT(traversal_ids[1])')
                   ).find_each(batch_size: 1000) do |namespace|
      root_ancestor_set.add(namespace)
    end

    # Group.joins(:cluster_groups).distinct.find_each(batch_size: 1000) do |namespace|
    #   root_ancestor_set.add(namespace.root_ancestor)
    # end
    #
    # Namespace.joins(projects: :cluster_project).distinct.find_each(batch_size: 1000) do |namespace|
    #   root_ancestor_set.add(namespace.root_ancestor)
    # end

    root_ancestor_set.each do |root_ancestor|
      Feature.enable(:certificate_based_clusters, root_ancestor)
    end
  end

  def down
    #  no op
  end
end
