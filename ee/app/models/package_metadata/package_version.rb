# frozen_string_literal: true

module PackageMetadata
  class PackageVersion < ApplicationRecord
    self.primary_key = :id

    belongs_to :package, foreign_key: :pm_package_id, inverse_of: :package_versions, optional: false
    has_many :package_version_licenses, inverse_of: :package_version, foreign_key: :pm_package_version_id

    enum purl_type: ::Enums::Sbom.purl_types

    validates :purl_type, presence: true
    validates :version, presence: true, length: { maximum: 255 }
  end
end
