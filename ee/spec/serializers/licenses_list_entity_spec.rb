# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LicensesListEntity do
  let!(:pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }
  let(:license_compliance) { project.license_compliance }

  before do
    stub_feature_flags(license_scanning_sbom_scanner: false)
    stub_licensed_features(license_scanning: true)
  end

  it_behaves_like 'report list' do
    let(:name) { :licenses }
    let(:collection) { license_compliance.policies }
    let(:no_items_status) { :no_licenses }
  end
end
