# frozen_string_literal: true

module PackageMetadata
  class PackageVersion < ApplicationRecord
    belongs_to :package, class_name: 'PackageMetadata::Package', optional: false, foreign_key: :pm_package_id,
      inverse_of: :package_versions

    has_many :package_version_licenses, inverse_of: :package_version, foreign_key: :pm_package_version_id
    has_many :licenses, through: :package_version_licenses

    validates :version, presence: true, length: { maximum: 255 }
  end
end
