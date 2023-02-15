# frozen_string_literal: true

module PackageMetadata
  class SyncConfiguration
    BUCKET_NAME = 'prod-export-license-bucket-1a6c642fc4de57d4'
    VERSION_FORMAT = 'v1'
    PURL_TYPE_TO_REGISTRY_ID = {
      composer: "packagist",
      conan: "conan",
      gem: "rubygem",
      golang: "go",
      maven: "maven",
      npm: "npm",
      nuget: "nuget",
      pypi: "pypi"
    }.with_indifferent_access.freeze

    def self.all
      storage_type = get_storage_type
      ::Enums::PackageMetadata.purl_types.map do |purl_type, _|
        new(storage_type, BUCKET_NAME, VERSION_FORMAT, purl_type)
      end
    end

    def self.get_storage_type
      File.exist?(archive_path) ? :offline : :gcp
    end

    def self.archive_path
      Rails.root.join('vendor/package_metadata_db')
    end

    def self.registry(purl_type)
      PURL_TYPE_TO_REGISTRY_ID[purl_type].freeze
    end

    attr_accessor :storage_type, :base_uri, :version_format, :purl_type

    def initialize(storage_type, base_uri, version_format, purl_type)
      @storage_type = storage_type
      @base_uri = base_uri
      @version_format = version_format
      @purl_type = purl_type
    end
  end
end
