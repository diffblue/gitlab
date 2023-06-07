# frozen_string_literal: true

module PackageMetadata
  class Package < ApplicationRecord
    DEFAULT_LICENSES_IDX = 0
    OTHER_LICENSES_IDX   = 3

    has_many :package_versions, inverse_of: :package, foreign_key: :pm_package_id

    include BulkInsertSafe

    enum purl_type: ::Enums::PackageMetadata.purl_types

    validates :purl_type, presence: true
    validates :name, presence: true, length: { maximum: 255 }
    validates :licenses, json_schema: { filename: 'pm_package_licenses' }, if: -> { licenses.present? }

    def license_ids_for(version:)
      # if the package metadata has not yet completed syncing, then the licenses field
      # might be nil, in which case we return an empty array.
      return [] if licenses.blank?

      matching_other_license_ids(version: version) || default_license_ids
    end

    # Takes an array of components and uses the purl_type and name fields to search for matching
    # packages
    def self.packages_for(components:)
      search_fields = [arel_table[:purl_type], arel_table[:name]]

      component_tuples = components.map do |component|
        purl_type_int = ::Enums::Sbom.purl_types[component.purl_type]
        component_tuple = [purl_type_int, component.name].map { |c| Arel::Nodes.build_quoted(c) }
        Arel::Nodes::Grouping.new(component_tuple)
      end

      where(Arel::Nodes::In.new(Arel::Nodes::Grouping.new(search_fields), component_tuples))
    end

    private

    def matching_other_license_ids(version:)
      other_licenses.each do |other_license|
        license_ids = other_license[0]
        versions = other_license[1]

        return license_ids if versions.include?(version)
      end

      nil
    end

    def default_license_ids
      licenses[DEFAULT_LICENSES_IDX]
    end

    def other_licenses
      licenses[OTHER_LICENSES_IDX]
    end
  end
end
