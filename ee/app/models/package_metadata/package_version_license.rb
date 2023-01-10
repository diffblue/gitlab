# frozen_string_literal: true

module PackageMetadata
  class PackageVersionLicense < ApplicationRecord
    self.primary_key = :purl_type

    belongs_to :package_version,
        foreign_key: :pm_package_version_id,
        inverse_of: :package_version_licenses,
        optional: false

    belongs_to :license,
        foreign_key: :pm_license_id,
        inverse_of: :package_version_licenses,
        optional: false

    enum purl_type: ::Enums::Sbom.purl_types

    validates :purl_type, presence: true
  end
end
