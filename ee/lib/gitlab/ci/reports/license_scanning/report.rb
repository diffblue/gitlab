# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module LicenseScanning
        class Report
          delegate :empty?, :fetch, :[], to: :found_licenses
          attr_accessor :version

          def initialize(version: '1.0')
            @version = version
            @found_licenses = {}
          end

          def major_version
            version.split('.')[0]
          end

          def licenses
            found_licenses.values.sort_by { |license| license.name.downcase }
          end

          def license_names
            found_licenses.values.map(&:name)
          end

          def add_license(id:, name:, url: '')
            add(::Gitlab::Ci::Reports::LicenseScanning::License.new(id: id, name: name, url: url))
          end

          def add(license)
            found_licenses[license.canonical_id] ||= license
          end

          def dependency_names
            found_licenses.values.flat_map(&:dependencies).map(&:name).uniq
          end

          def by_license_name(name)
            licenses.find { |license| license.name.casecmp?(name) }
          end

          def violates?(software_license_policies)
            policies_with_matching_license_name = software_license_policies.denied.with_license_by_name(license_names)
            policies_with_matching_spdx_id = software_license_policies.denied.by_spdx(licenses.map(&:id).compact)
            policies_with_matching_spdx_id.or(policies_with_matching_license_name).exists?
          end

          def violates_for_licenses?(software_license_policies, ids, names)
            policies_with_matching_license_name = software_license_policies.denied.with_license_by_name(names)
            policies_with_matching_spdx_id = software_license_policies.denied.by_spdx(ids)
            policies_with_matching_spdx_id.or(policies_with_matching_license_name).exists?
          end

          def diff_with(other_report)
            base = self.licenses
            head = other_report&.licenses || []

            {
              added: (head - base),
              unchanged: (base & head),
              removed: (base - head)
            }
          end

          private

          attr_reader :found_licenses
        end
      end
    end
  end
end
