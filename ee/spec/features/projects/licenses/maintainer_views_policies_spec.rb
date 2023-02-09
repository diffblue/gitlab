# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'EE > Projects > Licenses > Maintainer views policies', :js, feature_category: :projects do
  let!(:packages) do
    [
      create(:pm_package, name: "activesupport", purl_type: "gem", version: "5.1.4", spdx_identifiers: ["MIT"]),
      create(:pm_package, name: "github.com/sirupsen/logrus", purl_type: "golang", version: "v1.4.2",
        spdx_identifiers: ["MIT", "BSD-3-Clause"]),
      create(:pm_package, name: "org.apache.logging.log4j/log4j-api", purl_type: "maven", version: "2.6.1",
        spdx_identifiers: ["BSD-3-Clause"]),
      create(:pm_package, name: "yargs", purl_type: "npm", version: "11.1.0", spdx_identifiers: ["unknown"])
    ]
  end

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
    context 'when the license_scanning_sbom_scanner feature flag is false' do
      before_all do
        stub_feature_flags(license_scanning_sbom_scanner: false)
      end

      it 'displays a link to the documentation to configure license compliance' do
        expect(page).to have_content('License Compliance')
        expect(page).to have_content('More Information')
      end
    end

    context 'when the license_scanning_sbom_scanner feature flag is true' do
      it 'displays a link to the documentation to configure license compliance' do
        expect(page).to have_content('License Compliance')
        expect(page).to have_content('More Information')
      end
    end
  end

  context "when a pipeline exists" do
    let_it_be(:pipeline) do
      create(:ee_ci_pipeline, project: project, status: :success,
        builds: [create(:ee_ci_build, :license_scan_v2, :success), create(:ee_ci_build, :cyclonedx, :success)])
    end

    context 'when the license_scanning_sbom_scanner feature flag is false' do
      before_all do
        stub_feature_flags(license_scanning_sbom_scanner: false)
      end

      it 'displays licenses detected in the most recent scan report' do
        known_licenses.each do |license|
          selector = "div[data-spdx-id='#{license['id']}'"
          expect(page).to have_selector(selector)

          row = page.find(selector)
          policy = policy_for(license['id'])
          expect(row).to have_content(policy&.name || license['name'])
          expect(row).to have_content(dependencies_for(license['id']).join(' and '))
        end
      end
    end

    context 'when the license_scanning_sbom_scanner feature flag is true' do
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
    end

    context "when viewing the configured policies" do
      before do
        click_link('Policies')
        wait_for_requests
      end

      it 'displays the classification' do
        selector = "div[data-testid='admin-license-compliance-row']"
        expect(page).to have_selector(selector)

        row = page.find(selector)
        expect(row).to have_content(mit_license.name)
        expect(row).to have_content(mit_policy.classification.titlecase)
      end
    end
  end

  def label_for(dependency)
    name = dependency['name']
    version = dependency['version']
    version ? "#{name} (#{version})" : name
  end

  def sbom_packages_for(spdx_id)
    packages.find_all { |package| package.package_versions.first.licenses.map(&:spdx_identifier).include?(spdx_id) }
      .map { |package| "#{package.name} (#{package.package_versions.first.version})" }
  end

  def dependencies_for(spdx_id)
    report['dependencies']
      .find_all { |dependency| dependency['licenses'].include?(spdx_id) }
      .map { |dependency| label_for(dependency) }
  end

  def policy_for(license_id)
    SoftwareLicensePolicy.by_spdx(license_id).first
  end
end
