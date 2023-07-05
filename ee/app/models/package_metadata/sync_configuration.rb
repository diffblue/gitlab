# frozen_string_literal: true

module PackageMetadata
  class SyncConfiguration
    VERSION_FORMAT_V1 = 'v1'
    VERSION_FORMAT_V2 = 'v2'
    STORAGE_LOCATIONS = {
      advisories: {
        offline: Rails.root.join('vendor/advisory_package_metadata_db').freeze,
        gcp: 'prod-export-advisory-bucket-1a6c642fc4de57d4'
      },
      licenses: {
        offline: Rails.root.join('vendor/package_metadata_db').freeze,
        gcp: 'prod-export-license-bucket-1a6c642fc4de57d4'
      }
    }.with_indifferent_access.freeze

    PURL_TYPE_TO_REGISTRY_ID = {
      composer: "packagist",
      conan: "conan",
      gem: "rubygem",
      golang: "go",
      maven: "maven",
      npm: "npm",
      nuget: "nuget",
      pypi: "pypi",
      apk: "apk",
      rpm: "rpm",
      deb: "deb",
      cbl_mariner: "cbl-mariner"

    }.with_indifferent_access.freeze

    def self.all_configs_for_advisories
      storage_type, base_uri = get_storage_and_base_uri_for('advisories')

      permitted_purl_types.map do |purl_type, _|
        new('advisories', storage_type, base_uri, VERSION_FORMAT_V2, purl_type)
      end
    end

    def self.all_configs_for_licenses
      storage_type, base_uri = get_storage_and_base_uri_for('licenses')

      configs = []

      if Feature.enabled?(:compressed_package_metadata_synchronization)
        configs.concat(permitted_purl_types.map do |purl_type, _|
          new('licenses', storage_type, base_uri, VERSION_FORMAT_V2, purl_type)
        end)
      end

      if Feature.enabled?(:package_metadata_synchronization)
        configs.concat(permitted_purl_types.map do |purl_type, _|
          new('licenses', storage_type, base_uri, VERSION_FORMAT_V1, purl_type)
        end)
      end

      configs
    end

    def self.get_storage_and_base_uri_for(data_type)
      data = STORAGE_LOCATIONS[data_type]

      return [:offline, data[:offline]] if File.exist?(data[:offline])

      [:gcp, data[:gcp]]
    end

    def self.registry_id(purl_type)
      PURL_TYPE_TO_REGISTRY_ID[purl_type].freeze
    end

    def self.permitted_purl_types
      ::Gitlab::CurrentSettings.current_application_settings.package_metadata_purl_types_names
    end

    attr_accessor :data_type, :storage_type, :base_uri, :version_format, :purl_type

    def initialize(data_type, storage_type, base_uri, version_format, purl_type)
      @data_type = data_type
      @storage_type = storage_type
      @base_uri = base_uri
      @version_format = version_format
      @purl_type = purl_type
    end

    def v2?
      version_format == 'v2'
    end

    def advisories?
      data_type == 'advisories'
    end
  end
end
