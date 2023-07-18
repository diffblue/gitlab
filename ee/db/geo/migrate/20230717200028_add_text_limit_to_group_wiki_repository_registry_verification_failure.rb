# frozen_string_literal: true

class AddTextLimitToGroupWikiRepositoryRegistryVerificationFailure < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :group_wiki_repository_registry, :verification_failure, 255
  end

  def down
    remove_text_limit :group_wiki_repository_registry, :verification_failure
  end
end
