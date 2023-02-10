# frozen_string_literal: true

module Geo
  class ProjectWikiRepositoryState < ApplicationRecord
    include ::Geo::VerificationStateDefinition

    self.primary_key = :project_id

    belongs_to :project

    belongs_to :project_wiki_repository,
               class_name: 'Projects::WikiRepository',
               inverse_of: :wiki_repository_state

    validates :verification_failure, length: { maximum: 255 }
    validates :verification_state, :project, :project_wiki_repository, presence: true
    validates :project, uniqueness: true
  end
end
