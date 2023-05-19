# frozen_string_literal: true

FactoryBot.define do
  factory :pm_package, class: 'PackageMetadata::Package' do
    purl_type { :npm }
    sequence(:name) { |n| "package-#{n}" }

    # convert from license names to license id values, so we can specify licenses using
    # "OLDAP-2.1", for example, instead of needing to know the exact license id value.
    licenses do
      default_license_ids = default_license_names.map do |spdx_id|
        create(:pm_license, :with_software_license, spdx_identifier: spdx_id).id
      end

      other_licenses_with_ids = other_licenses.map do |l|
        s = l[:license_names].map do |spdx_id|
          create(:pm_license, :with_software_license, spdx_identifier: spdx_id).id
        end
        [s, l[:versions]]
      end

      [default_license_ids, lowest_version, highest_version, other_licenses_with_ids]
    end

    # these attributes allow using human-readable field names to specify
    # the default_licenses, highest_version and other_licenses.
    #
    # For example:
    #
    # create(:pm_package, name: "cliui", purl_type: "npm", default_license_names: ["OLDAP-2.1"],
    #   highest_version: "v1.0.0", other_licenses: [{ license_names: ["OLDAP-2.3"], versions: ["v1.1.0"] }])
    #
    # without these attributes, we'd need to use the following, which is difficult to understand:
    #
    # create(:pm_package, name: "cliui", purl_type: "npm", licenses: [[1], 'v1.0.0', [[[2], ['v1.1.0']]]])
    transient do
      highest_version do
        "#{'v' if purl_type == 'golang'}99999999"
      end

      lowest_version do
        "#{'v' if purl_type == 'golang'}00000001"
      end

      default_license_names { ["DEFAULT-2.1"] }

      other_licenses { [license_names: ["NON-DEFAULT-2.1"], versions: ['1.0.0']] }
    end

    initialize_with do
      PackageMetadata::Package.find_or_initialize_by(name: name, purl_type: purl_type)
    end
  end
end
