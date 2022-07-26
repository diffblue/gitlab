# frozen_string_literal: true

class RemoveTmpIndexGroupMembershipNamespaceIdColumn < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'tmp_index_for_namespace_id_migration_on_group_members'

  disable_ddl_transaction!
 

  def up
    remove_concurrent_index_by_name :group_members, INDEX_NAME
  end

  def down
    add_concurrent_index :group_members,
      :id,
      where: "group_members.namespace_id is null and group_members.source_type = 'Namespace'",
      name: INDEX_NAME
  end
end
