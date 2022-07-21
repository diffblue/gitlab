# frozen_string_literal: true

class Geo::GroupWikiRepositoryRegistry < Geo::BaseRegistry
  include Geo::ReplicableRegistry

  MODEL_CLASS = ::GroupWikiRepository
  MODEL_FOREIGN_KEY = :group_wiki_repository_id

  belongs_to :group_wiki_repository, class_name: 'GroupWikiRepository'

  # Remove this as part of the Group wiki repository verification implementation
  #
  # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/323897
  def verified_at
  end

  # Remove this as part of the Group wiki repository verification implementation
  #
  # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/323897
  def verification_retry_at
  end
end
