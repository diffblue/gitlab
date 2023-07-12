# frozen_string_literal: true

module Geo
  class ProjectWikiRepositoryRegistry < Geo::BaseRegistry
    include IgnorableColumns
    include ::Geo::ReplicableRegistry
    include ::Geo::VerifiableRegistry
    extend ::Gitlab::Utils::Override

    MODEL_CLASS = ::Projects::WikiRepository
    MODEL_FOREIGN_KEY = :project_wiki_repository_id

    ignore_column :force_to_redownload, remove_with: '16.4', remove_after: '2023-08-22'

    belongs_to :project_wiki_repository, class_name: 'Projects::WikiRepository'

    validates :project_wiki_repository, presence: true, uniqueness: true

    delegate :project, :wiki_repository_state, to: :project_wiki_repository, allow_nil: true
  end
end
