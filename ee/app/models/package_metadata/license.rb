# frozen_string_literal: true

module PackageMetadata
  class License < ApplicationRecord
    validates :spdx_identifier, presence: true, length: { maximum: 50 }

    has_many :package_version_licenses, inverse_of: :license, foreign_key: :pm_license_id
  end
end
