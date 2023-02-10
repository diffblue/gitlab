# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LicensesListEntity do
  let!(:pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }
  let(:license_compliance) { project.license_compliance }

  before do
    stub_licensed_features(license_scanning: true)
  end

  context 'when the license_scanning_sbom_scanner feature flag is false' do
    before do
      stub_feature_flags(license_scanning_sbom_scanner: false)
    end

    it_behaves_like 'report list' do
      let(:name) { :licenses }
      let(:collection) { license_compliance.policies }
      let(:no_items_status) { :no_licenses }
    end
  end

  context 'when the license_scanning_sbom_scanner feature flag is true' do
    let!(:pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }

    before do
      create(:pm_package_version_license, :with_all_relations, name: "activesupport", purl_type: "gem",
        version: "5.1.4", license_name: "New BSD")
    end

    it_behaves_like 'report list' do
      let(:name) { :licenses }
      let(:collection) { license_compliance.policies }
      let(:no_items_status) { :no_licenses }
    end
  end
end
