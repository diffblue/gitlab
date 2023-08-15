# frozen_string_literal: true

module PackageMetadata
  class AffectedPackageDataObject
    def self.create(hash, purl_type)
      affected_package = hash
      affected_package['package_name'] = affected_package.delete('name') if affected_package.has_key?('name')
      new(purl_type: purl_type, **affected_package.transform_keys(&:to_sym))
    end

    attr_accessor :purl_type, :package_name, :affected_range, :solution, :fixed_versions, :distro_version,
      :versions, :overridden_advisory_fields, :pm_advisory_id

    def initialize(
      purl_type:, package_name:, affected_range:, solution: '', fixed_versions: '', distro_version: '',
      versions: [], overridden_advisory_fields: {})
      @purl_type = purl_type
      @package_name = package_name
      @affected_range = affected_range
      @solution = solution
      @fixed_versions = fixed_versions
      @distro_version = distro_version
      @versions = versions
      @overridden_advisory_fields = overridden_advisory_fields
    end
  end
end
