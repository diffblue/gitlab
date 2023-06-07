# frozen_string_literal: true

module PackageMetadata
  class License < ApplicationRecord
    has_many :package_version_licenses, inverse_of: :package_version, foreign_key: :pm_package_version_id

    include BulkInsertSafe

    validates :spdx_identifier, presence: true, length: { maximum: 50 }

    scope :with_spdx_identifiers, ->(spdx_identifiers) do
      where(spdx_identifier: spdx_identifiers)
    end
  end
end
