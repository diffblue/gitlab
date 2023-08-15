# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LicensesListEntity, feature_category: :security_policy_management do
  let!(:pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }
  let(:license_compliance) { project.license_compliance }

  before do
    stub_licensed_features(license_scanning: true)
  end

  context 'when querying uncompressed package metadata' do
    before do
      create(:pm_package_version_license, :with_all_relations,
        name: "activesupport", purl_type: "gem",
        version: "5.1.4", license_name: "New BSD")
    end

    it_behaves_like 'report list' do
      let(:name) { :licenses }
      let(:collection) { license_compliance.policies }
      let(:no_items_status) { :no_licenses }
    end
  end

  context 'when querying compressed package metadata' do
    before do
      create(:pm_package, name: "activesupport", purl_type: "gem",
        other_licenses: [{ license_names: ["MIT"], versions: ["5.1.4"] }])
    end

    it_behaves_like 'report list' do
      let(:name) { :licenses }
      let(:collection) { license_compliance.policies }
      let(:no_items_status) { :no_licenses }
    end
  end
end
