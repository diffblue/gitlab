# frozen_string_literal: true

class Geo::SnippetRepositoryRegistry < Geo::BaseRegistry
  include IgnorableColumns
  include ::Geo::ReplicableRegistry
  include ::Geo::VerifiableRegistry

  MODEL_CLASS = ::SnippetRepository
  MODEL_FOREIGN_KEY = :snippet_repository_id

  ignore_column :force_to_redownload, remove_with: '16.4', remove_after: '2023-08-22'

  belongs_to :snippet_repository, class_name: 'SnippetRepository'
end
