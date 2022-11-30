# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Gitlab::LicenseScanning::Report, :license_compliance do
  describe "#license_scanning_report" do
    subject(:report) { described_class.new(project, pipeline).license_scanning_report }

    let(:project) { build(:project, :repository) }

    before do
      stub_licensed_features(license_scanning: true)
    end

    context "when pipeline is blank" do
      let(:pipeline) { nil }

      it "returns an empty report" do
        is_expected.to be_a_kind_of(::Gitlab::Ci::Reports::LicenseScanning::Report)
        expect(report.licenses).to be_empty
      end
    end

    context "with license scanning artifact" do
      let(:pipeline) { build(:ee_ci_pipeline, :with_license_scanning_report, project: project) }

      it "returns a report with licenses" do
        is_expected.to be_a_kind_of(::Gitlab::Ci::Reports::LicenseScanning::Report)
        expect(report.license_names).not_to be_empty
      end
    end
  end
end
