# frozen_string_literal: true

module PackageMetadata
  class License < ApplicationRecord
    has_many :package_version_licenses, inverse_of: :package_version, foreign_key: :pm_package_version_id

    validates :spdx_identifier, presence: true, length: { maximum: 50 }
  end
end
