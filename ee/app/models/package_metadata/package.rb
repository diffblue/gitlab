# frozen_string_literal: true

module PackageMetadata
  class Package < ApplicationRecord
    has_many :package_versions, inverse_of: :package, foreign_key: :pm_package_id

    enum purl_type: ::Enums::PackageMetadata.purl_types

    validates :purl_type, presence: true
    validates :name, presence: true, length: { maximum: 255 }
    validates :licenses, json_schema: { filename: 'pm_package_licenses' }, if: -> { licenses.present? }
  end
end
