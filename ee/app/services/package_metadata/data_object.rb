# frozen_string_literal: true

require 'csv'

module PackageMetadata
  class DataObject
    EXPECTED_CSV_FIELDS = 3
    MAX_NAME_LENGTH = 255
    MAX_VERSION_LENGTH = 255
    MAX_LICENSE_LENGTH = 50

    def self.from_csv(text, purl_type)
      parsed = CSV.parse_line(text.dup.force_encoding('UTF-8'))&.reject { |field| field.nil? || field.empty? }
      return unless parsed&.count == EXPECTED_CSV_FIELDS

      name = parsed[0].slice(0, MAX_NAME_LENGTH)
      version = parsed[1].slice(0, MAX_VERSION_LENGTH)
      license = parsed[2].slice(0, MAX_LICENSE_LENGTH)
      new(name, version, license, purl_type)
    rescue CSV::MalformedCSVError => e
      Gitlab::AppJsonLogger.error(class: self.name, message: 'csv parsing error', error: e)
      nil
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
