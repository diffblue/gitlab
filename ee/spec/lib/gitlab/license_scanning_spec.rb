# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Gitlab::LicenseScanning, feature_category: :license_compliance do
  let_it_be(:project) { create(:project, :repository, create_branch: "license_scanning_branch") }
  let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }

  describe "#scanner_for_project" do
    context "with default ref" do
      subject(:scanner) { described_class.scanner_for_project(project) }

      it "returns an artifact scanner" do
        is_expected.to be_a_kind_of(::Gitlab::LicenseScanning::ArtifactScanner)
      end

      it "contains a pipeline" do
        expect(scanner.pipeline).to eq(pipeline)
      end
    end

    context "with provided ref" do
      subject(:scanner) { described_class.scanner_for_project(project, "license_scanning_branch") }

      let_it_be(:pipeline_2) do
        create(:ee_ci_pipeline, :with_license_scanning_report, project: project, ref: "license_scanning_branch")
      end

      it "contains a pipeline" do
        expect(scanner.pipeline).to eq(pipeline_2)
      end
    end
  end

  describe "#scanner_for_pipeline" do
    context "with default branch pipeline" do
      subject(:scanner) { described_class.scanner_for_pipeline(pipeline) }

      it "returns an artifact scanner" do
        is_expected.to be_a_kind_of(::Gitlab::LicenseScanning::ArtifactScanner)
      end

      it "returns a pipeline" do
        expect(scanner.pipeline).to eq(pipeline)
      end
    end

    context "with non-default branch pipeline" do
      subject(:scanner) { described_class.scanner_for_pipeline(pipeline_2) }

      let_it_be(:pipeline_2) do
        create(:ee_ci_pipeline, :with_license_scanning_report, project: project, ref: "license_scanning_branch")
      end

      it "returns a pipeline" do
        expect(scanner.pipeline).to eq(pipeline_2)
      end
    end
  end
end
