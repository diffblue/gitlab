# frozen_string_literal: true

module Geo
  class ProjectWikiRepositoryState < ApplicationRecord
    include ::Geo::VerificationStateDefinition
    include EachBatch

    self.primary_key = :project_id

    belongs_to :project, inverse_of: :wiki_repository_state

    validates :verification_failure, length: { maximum: 255 }
    validates :verification_state, :project, presence: true
  end
end
