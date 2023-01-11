# frozen_string_literal: true

module PackageMetadata
  class PackageVersion < ApplicationRecord
    belongs_to :package, foreign_key: :pm_package_id, inverse_of: :package_versions, optional: false
    has_many :package_version_licenses, inverse_of: :package_version, foreign_key: :pm_package_version_id

    validates :version, presence: true, length: { maximum: 255 }
  end
end
