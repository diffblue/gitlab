# frozen_string_literal: true

module PackageMetadata
  class PackageVersionLicense < ApplicationRecord
    belongs_to :package_version, class_name: 'PackageMetadata::PackageVersion', optional: false,
      foreign_key: :pm_package_version_id, inverse_of: :package_version_licenses
    belongs_to :license, class_name: 'PackageMetadata::License', optional: false, foreign_key: :pm_license_id,
      inverse_of: :package_version_licenses
  end
end
