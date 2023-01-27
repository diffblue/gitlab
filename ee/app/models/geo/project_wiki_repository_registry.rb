# frozen_string_literal: true

module Geo
  class ProjectWikiRepositoryRegistry < Geo::BaseRegistry
    include ::Geo::ReplicableRegistry
    include ::Geo::VerifiableRegistry
    extend ::Gitlab::Utils::Override

    MODEL_CLASS = ::Projects::WikiRepository
    MODEL_FOREIGN_KEY = :project_wiki_repository_id

    belongs_to :project_wiki_repository, class_name: 'Projects::WikiRepository'

    validates :project_wiki_repository, presence: true, uniqueness: true

    delegate :project, :wiki_repository_state, to: :project_wiki_repository, allow_nil: true

    private

    override :ready_to_verify?
    def ready_to_verify?
      primary_wiki_repository_checksum.present?
    end

    def primary_wiki_repository_checksum
      wiki_repository_state&.verification_checksum
    end
  end
end
