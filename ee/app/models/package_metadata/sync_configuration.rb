# frozen_string_literal: true

module PackageMetadata
  class SyncConfiguration
    include Gitlab::Utils::StrongMemoize

    VERSION_FORMAT_V1 = 'v1'
    VERSION_FORMAT_V2 = 'v2'

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

    def self.configs_for(data_type)
      case data_type
      when 'advisories'
        advisory_configs
      when 'licenses'
        license_configs
      else
        raise NoMethodError, "unsupported data type: #{data_type}"
      end
    end

    def self.advisory_configs
      return [] unless Feature.enabled?(:package_metadata_advisory_sync)

      storage_type, base_uri = Location.for_advisories

      permitted_purl_types.map do |purl_type, _|
        new('advisories', storage_type, base_uri, VERSION_FORMAT_V2, purl_type)
      end
    end

    def self.license_configs
      storage_type, base_uri = Location.for_licenses

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

    def to_s
      "#{data_type}:#{storage_type}/#{base_uri}/#{version_format}/#{purl_type}"
    end
    strong_memoize_attr :to_s

    class Location
      LICENSES_PATH = Rails.root.join('vendor/package_metadata/licenses').freeze
      # old licenses path did not differentiate between data_types
      OLD_LICENSES_PATH = Rails.root.join('vendor/package_metadata_db').freeze
      LICENSES_BUCKET = 'prod-export-license-bucket-1a6c642fc4de57d4'
      ADVISORIES_PATH = Rails.root.join('vendor/package_metadata/advisories').freeze
      ADVISORIES_BUCKET = 'prod-export-advisory-bucket-1a6c642fc4de57d4'

      def self.for_licenses
        if File.exist?(LICENSES_PATH)
          [:offline, LICENSES_PATH]
        elsif File.exist?(OLD_LICENSES_PATH)
          [:offline, OLD_LICENSES_PATH]
        else
          [:gcp, LICENSES_BUCKET]
        end
      end

      def self.for_advisories
        if File.exist?(ADVISORIES_PATH)
          [:offline, ADVISORIES_PATH]
        else
          [:gcp, ADVISORIES_BUCKET]
        end
      end
    end
  end
end
