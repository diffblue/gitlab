# frozen_string_literal: true

module PackageMetadata
  class Checkpoint < ApplicationRecord
    self.primary_key = :purl_type

    enum purl_type: ::Enums::PackageMetadata.purl_types
    enum data_type: ::Enums::PackageMetadata.data_types
    enum version_format: ::Enums::PackageMetadata.version_formats

    validates :data_type, presence: true
    validates :version_format, presence: true
    validates :sequence, presence: true, numericality: { only_integer: true }
    validates :chunk, presence: true, numericality: { only_integer: true }
    validates :purl_type, presence: true, uniqueness: { scope: [:data_type, :version_format] }

    scope :with_purl_type, ->(purl_type) do
      find_or_initialize_by(purl_type: purl_type)
    end
  end
end
