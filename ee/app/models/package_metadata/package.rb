# frozen_string_literal: true

module PackageMetadata
  class Package < ApplicationRecord
    self.primary_key = :id

    enum purl_type: ::Enums::Sbom.purl_types

    validates :purl_type, presence: true
    validates :name, presence: true, length: { maximum: 255 }

    has_many :package_versions, inverse_of: :package, foreign_key: :pm_package_id
  end
end
