# frozen_string_literal: true

module PackageMetadata
  class DataObject
    EXPECTED_NUMBER_OF_FIELDS = 3
    MAX_NAME_LENGTH = 255
    MAX_VERSION_LENGTH = 255
    MAX_LICENSE_LENGTH = 50

    def self.create(data, purl_type)
      unless data&.compact&.size == EXPECTED_NUMBER_OF_FIELDS
        Gitlab::AppJsonLogger.warn(class: name,
          message: "Invalid data passed to .create: #{data}")
        return
      end

      name = data[0].slice(0, MAX_NAME_LENGTH)
      version = data[1].slice(0, MAX_VERSION_LENGTH)
      license = data[2].slice(0, MAX_LICENSE_LENGTH)
      new(name, version, license, purl_type)
    end

    attr_accessor :version, :license, :purl_type,
      :package_id, :package_version_id, :license_id

    def initialize(name, version, license, purl_type)
      @name = name
      @version = version
      @license = license
      @purl_type = purl_type
    end

    def ==(other)
      name == other.name &&
        version == other.version &&
        license == other.license &&
        purl_type == other.purl_type
    end

    def name
      ::Sbom::PackageUrl::Normalizer.new(type: purl_type, text: @name)
        .normalize_name
    end
  end
end
