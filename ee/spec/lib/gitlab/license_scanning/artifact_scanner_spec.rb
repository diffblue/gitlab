# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Gitlab::LicenseScanning::ArtifactScanner, feature_category: :software_composition_analysis do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:ref) { "license_scanning_example" }

  subject(:scanner) { described_class.new(project, pipeline) }

  before do
    stub_licensed_features(license_scanning: true)
  end

  describe ".latest_pipeline" do
    context "when the pipeline contains a license_scanning report" do
      let_it_be(:pipeline_with_ref) do
        create(:ee_ci_pipeline, :with_license_scanning_report, project: project, ref: ref)
      end

      subject(:latest_pipeline) { described_class.latest_pipeline(project, ref) }

      it "returns the latest pipeline with a report for the specified ref" do
        expect(latest_pipeline).to eq(pipeline_with_ref)
      end
    end

    context 'when the pipeline does not contain a license_scanning report' do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_metrics_report, project: project) }

      it "returns nil" do
        expect(described_class.latest_pipeline(project, project.default_branch)).to be_nil
      end
    end
  end

  describe "#report" do
    context "when pipeline contains a license scanning report" do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }

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

  describe "#latest_build_for_default_branch" do
    subject(:ci_build) { described_class.new(project, pipeline).latest_build_for_default_branch }

    context "when project has license scanning jobs" do
      let_it_be(:pipeline) do
        create(:ee_ci_pipeline, :with_license_scanning_report, project: project, ref: ref)
      end

      let_it_be(:default_branch_pipeline) do
        create(:ee_ci_pipeline, :with_license_scanning_report, project: project, ref: project.default_branch)
      end

      it "returns build for default branch" do
        expect(ci_build.pipeline).to eql(default_branch_pipeline)
      end
    end

    context "when project has no license scanning jobs" do
      let_it_be(:pipeline) do
        create(:ee_ci_pipeline, :with_metrics_report, project: project, ref: project.default_branch)
      end

      it "returns a nil result" do
        expect(ci_build).to be_nil
      end
    end
  end
end
