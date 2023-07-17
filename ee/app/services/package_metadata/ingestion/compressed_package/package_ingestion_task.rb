# frozen_string_literal: true

module PackageMetadata
  module Ingestion
    module CompressedPackage
      class PackageIngestionTask
        def initialize(import_data, license_map)
          @import_data = import_data
          @license_map = license_map
        end

        def self.execute(import_data, license_map)
          new(import_data, license_map).execute
        end

        def execute
          PackageMetadata::Package.bulk_upsert!(valid_packages, unique_by: %w[purl_type name])
        end

        private

        attr_reader :import_data, :license_map

        # validate checks the list of provided package models and returns
        # only those which are valid and logs the invalid packages as an error
        def valid_packages
          packages.filter do |package|
            if package.valid?
              true
            else
              Gitlab::AppJsonLogger.error(class: self.class.name,
                message: "invalid package #{package.purl_type}/#{package.name}", errors: package.errors.to_hash)
              false
            end
          end.uniq(&:name)
        end

        def packages
          import_data.map do |data_object|
            builder.build(data_object)
          end
        end

        def builder
          @builder ||= PackageBuilder.new(license_map)
        end

        class PackageBuilder
          def initialize(license_map)
            @license_map = license_map
          end

          # build a new model object by assigning attributes and converting
          # data_object licenses into the compressed tuple expected by the
          # model and mapping license spdx_identifiers into their ids
          def build(data_object)
            PackageMetadata::Package.new(
              name: data_object.name,
              purl_type: data_object.purl_type,
              licenses: [
                convert(data_object.default_licenses),
                data_object.lowest_version,
                data_object.highest_version,
                convert_other(data_object.other_licenses)
              ],
              created_at: now,
              updated_at: now
            )
          end

          private

          attr_reader :license_map

          def convert(spdx_identifiers)
            spdx_identifiers.map { |spdx_identifier| license_map[spdx_identifier] }
          end

          # convert other_licenses by converting the data_object's list of hashes
          # into a list of tuples and converting the spdx_identifiers to their
          # ids
          def convert_other(other_licenses)
            other_licenses.map { |hash| [convert(hash['licenses']), hash['versions']] }
          end

          def now
            @now ||= Time.zone.now
          end
        end
      end
    end
  end
end
