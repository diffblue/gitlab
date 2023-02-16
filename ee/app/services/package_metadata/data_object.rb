# frozen_string_literal: true

require 'csv'

module PackageMetadata
  class DataObject
    def self.from_csv(text, purl_type)
      parsed = CSV.parse_line(text)&.reject { |field| field.nil? || field.empty? }
      new(parsed[0], parsed[1], parsed[2], purl_type) if parsed&.count == 3
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
