# frozen_string_literal: true

module Geo
  class ProjectWikiRepositoryRegistry < Geo::BaseRegistry
    include ::Geo::ReplicableRegistry
    include ::Geo::VerifiableRegistry
    extend ::Gitlab::Utils::Override

    MODEL_CLASS = ::Project
    MODEL_FOREIGN_KEY = :project_id

    belongs_to :project, class_name: 'Project'

    private

    override :ready_to_verify?
    def ready_to_verify?
      primary_wiki_repository_checksum.present?
    end

    def primary_wiki_repository_checksum
      project.wiki_repository_state&.verification_checksum || project.repository_state&.wiki_verification_checksum
    end
  end
end
