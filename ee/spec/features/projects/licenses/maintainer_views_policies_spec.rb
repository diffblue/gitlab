# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'EE > Projects > Licenses > Maintainer views policies', :js, feature_category: :projects do
  let_it_be(:project) { create(:project) }
  let_it_be(:maintainer) do
    create(:user).tap do |user|
      project.add_maintainer(user)
    end
  end

  before do
    stub_feature_flags(license_scanning_sbom_scanner: false)
    stub_licensed_features(license_scanning: true)

    sign_in(maintainer)
    visit(project_licenses_path(project))
    wait_for_requests
  end

  context 'when policies are not configured' do
    it 'displays a link to the documentation to configure license compliance' do
      expect(page).to have_content('License Compliance')
      expect(page).to have_content('More Information')
    end
  end

  context "when a policy is configured" do
    let_it_be(:mit) { create(:software_license, :mit) }
    let_it_be(:mit_policy) { create(:software_license_policy, :denied, software_license: mit, project: project) }
    let_it_be(:pipeline) { create(:ee_ci_pipeline, project: project, builds: [create(:ee_ci_build, :license_scan_v2, :success)], status: :success) }

    let(:report) { Gitlab::Json.parse(fixture_file('security_reports/license_compliance/gl-license-scanning-report-v2.json', dir: 'ee')) }
    let(:known_licenses) { report['licenses'].find_all { |license| license['url'].present? } }

    it 'displays licenses detected in the most recent scan report' do
      known_licenses.each do |license|
        selector = "div[data-spdx-id='#{license['id']}'"
        expect(page).to have_selector(selector)

        row = page.find(selector)
        policy = policy_for(license)
        expect(row).to have_content(policy&.name || license['name'])
        expect(row).to have_content(dependencies_for(license['id']).join(' and '))
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
        expect(row).to have_content(mit.name)
        expect(row).to have_content(mit_policy.classification.titlecase)
      end
    end

    def label_for(dependency)
      name = dependency['name']
      version = dependency['version']
      version ? "#{name} (#{version})" : name
    end

    def dependencies_for(spdx_id)
      report['dependencies']
        .find_all { |dependency| dependency['licenses'].include?(spdx_id) }
        .map { |dependency| label_for(dependency) }
    end

    def policy_for(license)
      SoftwareLicensePolicy.by_spdx(license['id']).first
    end
  end
end
