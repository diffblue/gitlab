# frozen_string_literal: true

module PackageMetadata
  class Checkpoint < ApplicationRecord
    enum purl_type: ::Enums::PackageMetadata.purl_types
    enum data_type: ::Enums::PackageMetadata.data_types
    enum version_format: ::Enums::PackageMetadata.version_formats

    validates :data_type, presence: true
    validates :version_format, presence: true
    validates :sequence, presence: true, numericality: { only_integer: true }
    validates :chunk, presence: true, numericality: { only_integer: true }
    validates :purl_type, presence: true, uniqueness: { scope: [:data_type, :version_format] }

    # These components uniquely identify the last sync position for a
    # path determined by data_type_bucket_or_dir/version_format/purl_type.
    def self.with_path_components(data_type, version_format, purl_type)
      find_or_initialize_by(data_type: data_type, purl_type: purl_type, version_format: version_format)
    end
  end
end
