# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class FinalizeMemberNamespaceIdNullCleanup < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'DestroyInvalidGroupMembers'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :members,
      column_name: :member_namespace_id,
      job_arguments: []
    )
  end

  def down
    # noop
  end
end
