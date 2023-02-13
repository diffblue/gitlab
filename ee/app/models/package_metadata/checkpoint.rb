# frozen_string_literal: true

module PackageMetadata
  class Checkpoint < ApplicationRecord
    self.primary_key = :purl_type

    enum purl_type: ::Enums::PackageMetadata.purl_types

    validates :purl_type, presence: true, uniqueness: true
    validates :sequence, presence: true, numericality: { only_integer: true }
    validates :chunk, presence: true, numericality: { only_integer: true }

    scope :with_purl_type, ->(purl_type) do
      find_or_initialize_by(purl_type: purl_type)
    end
  end
end
