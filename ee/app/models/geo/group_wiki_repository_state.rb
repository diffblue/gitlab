# frozen_string_literal: true

module Geo
  class GroupWikiRepositoryState < ApplicationRecord
    include ::Geo::VerificationStateDefinition

    belongs_to :group_wiki_repository,
      inverse_of: :group_wiki_repository_state

    validates :verification_state, :group_wiki_repository, presence: true
    validates :group_wiki_repository, uniqueness: true
  end
end
