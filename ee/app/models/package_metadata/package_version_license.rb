# frozen_string_literal: true

module PackageMetadata
  class PackageVersionLicense < ApplicationRecord
    belongs_to :package_version,
        foreign_key: :pm_package_version_id,
        inverse_of: :package_version_licenses,
        optional: false

    belongs_to :license,
        foreign_key: :pm_license_id,
        inverse_of: :package_version_licenses,
        optional: false
  end
end
