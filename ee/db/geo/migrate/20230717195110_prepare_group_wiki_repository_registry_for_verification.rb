# frozen_string_literal: true

class PrepareGroupWikiRepositoryRegistryForVerification < Gitlab::Database::Migration[2.1]
  def up
    add_column :group_wiki_repository_registry, :verified_at, :datetime_with_timezone
    add_column :group_wiki_repository_registry, :verification_started_at, :datetime_with_timezone
    add_column :group_wiki_repository_registry, :verification_retry_at, :datetime_with_timezone
    add_column :group_wiki_repository_registry, :verification_state, :integer, default: 0, null: false, limit: 2
    add_column :group_wiki_repository_registry, :verification_retry_count, :integer, default: 0, limit: 2, null: false
    add_column :group_wiki_repository_registry, :checksum_mismatch, :boolean, default: false, null: false
    add_column :group_wiki_repository_registry, :verification_checksum, :binary
    add_column :group_wiki_repository_registry, :verification_checksum_mismatched, :binary

    # rubocop:disable Migration/AddLimitToTextColumns
    # The limit is added in a separate migration
    add_column :group_wiki_repository_registry, :verification_failure, :text
    # rubocop:enable Migration/AddLimitToTextColumns
  end

  def down
    remove_column :group_wiki_repository_registry, :verified_at
    remove_column :group_wiki_repository_registry, :verification_started_at
    remove_column :group_wiki_repository_registry, :verification_retry_at
    remove_column :group_wiki_repository_registry, :verification_state
    remove_column :group_wiki_repository_registry, :verification_retry_count
    remove_column :group_wiki_repository_registry, :checksum_mismatch
    remove_column :group_wiki_repository_registry, :verification_checksum
    remove_column :group_wiki_repository_registry, :verification_checksum_mismatched
    remove_column :group_wiki_repository_registry, :verification_failure
  end
end
