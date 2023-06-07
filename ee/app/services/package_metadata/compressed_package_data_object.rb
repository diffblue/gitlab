# frozen_string_literal: true

module PackageMetadata
  class CompressedPackageDataObject
    def self.parse(text, purl_type)
      parsed = ::Gitlab::Json.parse(text)
      new(purl_type: purl_type, **parsed.transform_keys(&:to_sym))
    rescue JSON::ParserError => e
      Gitlab::AppJsonLogger.error(class: name, message: e.message)
      nil
    end

    attr_accessor :purl_type, :default_licenses, :lowest_version, :highest_version, :other_licenses

    def initialize(purl_type:, name:, default_licenses:, lowest_version: nil, highest_version: nil, other_licenses: [])
      @purl_type = purl_type
      @name = name
      @default_licenses = default_licenses
      @lowest_version = lowest_version
      @highest_version = highest_version
      @other_licenses = other_licenses
    end

    def ==(other)
      purl_type == other.purl_type &&
        name == other.name &&
        default_licenses == other.default_licenses &&
        lowest_version == other.lowest_version &&
        highest_version == other.highest_version &&
        other_licenses == other.other_licenses
    end

    def name
      ::Sbom::PackageUrl::Normalizer.new(type: purl_type, text: @name)
        .normalize_name
    end

    def spdx_identifiers
      default_licenses.concat(other_licenses.flat_map { |hash| hash['licenses'] })
        .sort.uniq
    end
  end
end
