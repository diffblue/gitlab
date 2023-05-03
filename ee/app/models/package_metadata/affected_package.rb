# frozen_string_literal: true

module PackageMetadata
  class AffectedPackage < ApplicationRecord
    include Gitlab::Utils::StrongMemoize
    belongs_to :advisory, class_name: 'PackageMetadata::Advisory', optional: false, foreign_key: :pm_advisory_id,
      inverse_of: :affected_packages

    enum purl_type: ::Enums::PackageMetadata.purl_types

    validates :purl_type, presence: true
    validates :package_name, presence: true, length: { maximum: 256 }
    validates :distro_version, length: { maximum: 256 }
    validates :solution, length: { maximum: 2048 }
    validates :affected_range, presence: true, length: { maximum: 512 }
    validates :overridden_advisory_fields, json_schema: { filename: 'pm_affected_package_overridden_advisory_fields' }
  end
end
