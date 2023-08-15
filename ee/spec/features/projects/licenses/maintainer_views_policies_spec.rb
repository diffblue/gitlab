# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'EE > Projects > Licenses > Maintainer views licenses', :js, feature_category: :groups_and_projects do
  let_it_be(:project) { create(:project) }
  let_it_be(:mit_license) { create(:software_license, :mit) }
  let_it_be(:mit_policy) { create(:software_license_policy, :denied, software_license: mit_license, project: project) }
  let_it_be(:report) { Gitlab::Json.parse(fixture_file('security_reports/license_compliance/gl-license-scanning-report-v2.json', dir: 'ee')) }
  let_it_be(:known_licenses) { report['licenses'].find_all { |license| license['url'].present? } }

  let_it_be(:maintainer) do
    create(:user).tap do |user|
      project.add_maintainer(user)
    end
  end

  before do
    stub_licensed_features(license_scanning: true)

    sign_in(maintainer)
    visit(project_licenses_path(project))
    wait_for_requests
  end

  context 'when no pipeline exists' do
    it 'displays a link to the documentation to configure license compliance' do
      expect(page).to have_content('License compliance')
      expect(page).to have_content('More Information')
    end
  end

  context "when a pipeline exists" do
    let_it_be(:pipeline) do
      create(:ee_ci_pipeline, project: project, status: :success,
        builds: [create(:ee_ci_build, :license_scan_v2, :success)])
    end

    context 'when querying uncompressed package metadata' do
      let!(:package_version_licenses) do
        [
          create(:pm_package_version_license, :with_all_relations, name: "activesupport",
            purl_type: "gem", version: "5.1.4", license_name: "MIT"),
          create(:pm_package_version_license, :with_all_relations, name: "github.com/sirupsen/logrus",
            purl_type: "golang", version: "v1.4.2", license_name: "MIT"),
          create(:pm_package_version_license, :with_all_relations, name: "github.com/sirupsen/logrus",
            purl_type: "golang", version: "v1.4.2", license_name: "BSD-3-Clause"),
          create(:pm_package_version_license, :with_all_relations, name: "org.apache.logging.log4j/log4j-api",
            purl_type: "maven", version: "2.6.1", license_name: "BSD-3-Clause")
        ]
      end

      before do
        stub_feature_flags(compressed_package_metadata_query: false)

        create(:ee_ci_pipeline, project: project, status: :success, builds: [create(:ee_ci_build, :cyclonedx, :success)])

        visit(project_licenses_path(project))
        wait_for_requests
      end

      it 'displays licenses detected in the most recent scan report' do
        known_licenses.each do |license|
          selector = "div[data-spdx-id='#{license['id']}'"
          expect(page).to have_selector(selector)

          row = page.find(selector)
          policy = policy_for(license['id'])
          expect(row).to have_content(policy&.name)
          expect(row).to have_content(sbom_packages_for(license['id']).join(' and '))
        end
      end

      def sbom_packages_for(spdx_id)
        package_version_licenses.find_all { |obj| obj.license.spdx_identifier.include?(spdx_id) }
          .map { |obj| "#{obj.package_version.package.name} (#{obj.package_version.version})" }
      end
    end

    context 'when querying compressed package metadata' do
      let!(:packages) do
        [
          create(:pm_package, name: "activesupport", purl_type: "gem",
            other_licenses: [{ license_names: ["MIT"], versions: ["5.1.4"] }]),
          create(:pm_package, name: "github.com/sirupsen/logrus", purl_type: "golang",
            other_licenses: [{ license_names: ["MIT", "BSD-3-Clause"], versions: ["v1.4.2"] }]),
          create(:pm_package, name: "org.apache.logging.log4j/log4j-api", purl_type: "maven",
            other_licenses: [{ license_names: ["BSD-3-Clause"], versions: ["2.6.1"] }])
        ]
      end

      before do
        create(:ee_ci_pipeline, project: project, status: :success, builds: [create(:ee_ci_build, :cyclonedx, :success)])

        visit(project_licenses_path(project))
        wait_for_requests
      end

      it 'displays licenses detected in the most recent scan report' do
        known_licenses.each do |license|
          selector = "div[data-spdx-id='#{license['id']}'"
          expect(page).to have_selector(selector)

          row = page.find(selector)
          policy = policy_for(license['id'])
          expect(row).to have_content(policy&.name)
          expect(row).to have_content(compressed_sbom_packages_for(license['id']).join(' and '))
        end
      end

      def compressed_sbom_packages_for(spdx_id)
        sbom_packages = []
        packages.each do |package|
          package.licenses[PackageMetadata::Package::OTHER_LICENSES_IDX].each do |other_licenses|
            license_ids = other_licenses[0]
            license_versions = other_licenses[1]

            license_ids.each do |license_id|
              if PackageMetadata::License.find(license_id).spdx_identifier == spdx_id
                sbom_packages << "#{package.name} (#{license_versions[0]})"
              end
            end
          end
        end

        sbom_packages
      end
    end
  end

  def policy_for(license_id)
    SoftwareLicensePolicy.by_spdx(license_id).first
  end
end
