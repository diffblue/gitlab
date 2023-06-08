# frozen_string_literal: true

module Geo
  class WikiRepositoryState < ApplicationRecord
    include ::Geo::VerificationStateDefinition

    belongs_to :project_wiki_repository,
      class_name: 'Projects::WikiRepository',
      inverse_of: :wiki_repository_state

    validates :verification_state, :project_wiki_repository, presence: true
    validates :project_wiki_repository, uniqueness: true
  end
end
