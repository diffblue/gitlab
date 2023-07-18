# frozen_string_literal: true

module PackageMetadata
  class AdvisoryDataObject
    def self.create(data, purl_type)
      advisory = data['advisory'].clone
      advisory['advisory_xid'] = advisory.delete('id') if advisory.has_key?('id')
      advisory['source_xid'] = advisory.delete('source') if advisory.has_key?('source')

      packages = data['packages'].clone
      raise ArgumentError, 'Missing packages attribute' unless packages

      affected_packages = create_affected_packages(packages, purl_type)
      new(**advisory.transform_keys(&:to_sym), affected_packages: affected_packages)
    end

    def self.create_affected_packages(packages, purl_type)
      packages.map do |package_hash|
        AffectedPackageDataObject.create(package_hash, purl_type)
      end
    end

    attr_accessor :advisory_xid, :source_xid, :published_date, :title, :description, :cvss_v2, :cvss_v3, :urls,
      :identifiers, :affected_packages

    # rubocop:disable Metrics/ParameterLists
    def initialize(
      advisory_xid:, source_xid:, published_date:, title: '', description: '', cvss_v2: nil, cvss_v3: nil, urls: [],
      identifiers: [], affected_packages: [])
      # rubocop:enable Metrics/ParameterLists
      @advisory_xid = advisory_xid
      @source_xid = source_xid
      @published_date = published_date
      @title = title
      @description = description
      @cvss_v2 = cvss_v2
      @cvss_v3 = cvss_v3
      @urls = urls
      @identifiers = identifiers.map { |ident| ident.transform_keys(&:to_sym) }
      @affected_packages = affected_packages
    end
  end
end
