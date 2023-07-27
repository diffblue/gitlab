# frozen_string_literal: true

class Geo::GroupWikiRepositoryRegistry < Geo::BaseRegistry
  include IgnorableColumns
  include ::Geo::ReplicableRegistry
  include ::Geo::VerifiableRegistry

  MODEL_CLASS = ::GroupWikiRepository
  MODEL_FOREIGN_KEY = :group_wiki_repository_id

  ignore_column :force_to_redownload, remove_with: '16.4', remove_after: '2023-08-22'

  belongs_to :group_wiki_repository, class_name: 'GroupWikiRepository'
end
