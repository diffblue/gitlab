# frozen_string_literal: true

class Geo::GroupWikiRepositoryRegistry < Geo::BaseRegistry
  include IgnorableColumns
  include ::Geo::ReplicableRegistry

  MODEL_CLASS = ::GroupWikiRepository
  MODEL_FOREIGN_KEY = :group_wiki_repository_id

  ignore_column :force_to_redownload, remove_with: '16.4', remove_after: '2023-08-22'

  belongs_to :group_wiki_repository, class_name: 'GroupWikiRepository'

  class << self
    extend ::Gitlab::Utils::Override

    # TODO: Remove to make this resource available in the resync/reverify mutation
    # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/323897
    override :graphql_mutable?
    def graphql_mutable?
      false
    end
  end
end
