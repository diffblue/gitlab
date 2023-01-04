# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Gitlab::LicenseScanning::ArtifactScanner, feature_category: :license_compliance do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }

  subject(:scanner) { described_class.new(project, pipeline) }

  before do
    stub_licensed_features(license_scanning: true)
  end

  describe "#report" do
    context "when pipeline contains a license scanning report" do
      it "returns a non-empty report" do
        expect(scanner.report.empty?).to be_falsey
      end
    end

    context "when pipeline contains no license scanning report" do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_metrics_report, project: project) }

      it "returns an empty report" do
        expect(scanner.report.empty?).to be_truthy
      end
    end
  end

  describe "#latest_pipeline" do
    it "returns a pipeline" do
      expect(described_class.latest_pipeline(project, project.default_branch)).to eq(pipeline)
    end
  end

  describe "#has_data?" do
    context "when pipeline has a license scanning report" do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }

      it "returns true" do
        expect(scanner.has_data?).to be_truthy
      end
    end

    context "when pipeline has no license scanning report" do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, project: project) }

      it "returns false" do
        expect(scanner.has_data?).to be_falsey
      end
    end

    context "when pipeline is nil" do
      let(:pipeline) { nil }

      it "returns false" do
        expect(scanner.has_data?).to be_falsey
      end
    end
  end

  describe "#results_available?" do
    subject { described_class.new(project, pipeline).results_available? }

    context "when pipeline is running" do
      let_it_be(:pipeline) { create(:ci_pipeline, :running, project: project) }
      let_it_be(:build) { create(:ci_build, :license_scanning, pipeline: pipeline) }

      it { is_expected.to be_falsey }
    end

    context "when pipeline status is success" do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }

      it { is_expected.to be_truthy }
    end
  end
end
