# frozen_string_literal: true

module Geo
  class LfsObjectState < ApplicationRecord
    include ::Geo::VerificationStateDefinition

    self.primary_key = :lfs_object_id

    belongs_to :lfs_object, inverse_of: :lfs_object_state
  end
end
