# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Gitlab::LicenseScanning::Report, :license_compliance do
  let(:report) { described_class.new(project, pipeline) }
  let(:project) { build(:project, :repository) }

  describe "#license_scanning_report" do
    subject(:ls_report) { report.license_scanning_report }

    before do
      stub_licensed_features(license_scanning: true)
    end

    context "when pipeline is blank" do
      let(:pipeline) { nil }

      it "returns an empty report" do
        is_expected.to be_a_kind_of(::Gitlab::Ci::Reports::LicenseScanning::Report)
        expect(ls_report.licenses).to be_empty
      end
    end

    context "with license scanning artifact" do
      let(:pipeline) { build(:ee_ci_pipeline, :with_license_scanning_report, project: project) }

      it "returns a report with licenses" do
        is_expected.to be_a_kind_of(::Gitlab::Ci::Reports::LicenseScanning::Report)
        expect(ls_report.license_names).not_to be_empty
      end
    end
  end

  describe "#expose_license_scanning_data?" do
    subject { report.expose_license_scanning_data? }

    context 'when pipeline is blank' do
      let(:pipeline) { nil }

      it { is_expected.to be_falsey }
    end

    context 'when pipeline exists' do
      let(:pipeline) { build(:ee_ci_pipeline, project: project) }

      before do
        allow(pipeline).to receive(:expose_license_scanning_data?).and_return(true)
      end

      it { is_expected.to be_truthy }
    end
  end
end
