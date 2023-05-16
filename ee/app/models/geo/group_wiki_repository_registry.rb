# frozen_string_literal: true

class Geo::GroupWikiRepositoryRegistry < Geo::BaseRegistry
  include Geo::ReplicableRegistry

  MODEL_CLASS = ::GroupWikiRepository
  MODEL_FOREIGN_KEY = :group_wiki_repository_id

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
