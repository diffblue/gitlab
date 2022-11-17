# frozen_string_literal: true

module PackageMetadata
  class Package < ApplicationRecord
    enum purl_type: {
      composer: 1,
      conan: 2,
      gem: 3,
      golang: 4,
      maven: 5,
      npm: 6,
      nuget: 7,
      pypi: 8
    }.freeze

    validates :purl_type, presence: true
    validates :name, presence: true, length: { maximum: 255 }

    has_many :package_versions, inverse_of: :package, foreign_key: :pm_package_id
  end
end
