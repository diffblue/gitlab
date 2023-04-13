# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Gitlab::LicenseScanning, feature_category: :software_composition_analysis do
  let_it_be(:project) { create(:project, :repository, create_branch: "license_scanning_branch") }

  describe "#scanner_for_project" do
    subject(:scanner) { described_class.scanner_for_project(project) }

    context 'when the license_scanning_sbom_scanner feature flag is false' do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }

      before do
        stub_feature_flags(license_scanning_sbom_scanner: false)
      end

      it "returns an artifact scanner" do
        is_expected.to be_a_kind_of(::Gitlab::LicenseScanning::ArtifactScanner)
      end

      context "with default ref" do
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

    context 'when the license_scanning_sbom_scanner feature flag is true for the given project' do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }
      let_it_be(:latest_pipeline) { nil }

      before do
        stub_feature_flags(license_scanning_sbom_scanner: false)
        stub_feature_flags(license_scanning_sbom_scanner: project)
      end

      context "when project only has pipelines with a sbom report" do
        it "returns an sbom scanner" do
          expect(scanner).to be_a_kind_of(::Gitlab::LicenseScanning::SbomScanner)
        end

        context "with default ref" do
          it "contains a pipeline" do
            expect(scanner.pipeline).to eq(pipeline)
          end
        end

        context "with provided ref" do
          subject(:scanner) { described_class.scanner_for_project(project, "license_scanning_branch") }

          let_it_be(:pipeline_2) do
            create(:ee_ci_pipeline, :with_cyclonedx_report, project: project, ref: "license_scanning_branch")
          end

          it "contains a pipeline" do
            expect(scanner.pipeline).to eq(pipeline_2)
          end
        end
      end

      context "when project has pipelines with license scanning and sbom reports" do
        context "when the license scanning report is newer than the sbom report" do
          let_it_be(:latest_pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }

          it "returns an artifact scanner" do
            expect(scanner).to be_a_kind_of(::Gitlab::LicenseScanning::ArtifactScanner)
          end
        end

        context "when the sbom report is newer than the license scanning report" do
          let_it_be(:latest_pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }

          it "returns an sbom scanner" do
            expect(scanner).to be_a_kind_of(::Gitlab::LicenseScanning::SbomScanner)
          end
        end
      end
    end
  end

  describe "#scanner_for_pipeline" do
    subject(:scanner) { described_class.scanner_for_pipeline(project, pipeline) }

    context 'when the license_scanning_sbom_scanner feature flag is false' do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }

      before do
        stub_feature_flags(license_scanning_sbom_scanner: false)
      end

      context "with default branch pipeline" do
        it "returns an artifact scanner" do
          is_expected.to be_a_kind_of(::Gitlab::LicenseScanning::ArtifactScanner)
        end

        it "returns a pipeline" do
          expect(scanner.pipeline).to eq(pipeline)
        end
      end

      context "with non-default branch pipeline" do
        subject(:scanner) { described_class.scanner_for_pipeline(project, pipeline_2) }

        let_it_be(:pipeline_2) do
          create(:ee_ci_pipeline, :with_license_scanning_report, project: project, ref: "license_scanning_branch")
        end

        it "returns an artifact scanner" do
          is_expected.to be_a_kind_of(::Gitlab::LicenseScanning::ArtifactScanner)
        end

        it "returns a pipeline" do
          expect(scanner.pipeline).to eq(pipeline_2)
        end
      end
    end

    context 'when the license_scanning_sbom_scanner feature flag is true for the given pipeline.project' do
      before do
        stub_feature_flags(license_scanning_sbom_scanner: false)
        stub_feature_flags(license_scanning_sbom_scanner: project)
      end

      context "when pipeline has only an sbom report" do
        let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }

        it "returns an sbom scanner" do
          is_expected.to be_a_kind_of(::Gitlab::LicenseScanning::SbomScanner)
        end

        context "with default branch pipeline" do
          it "returns a pipeline" do
            expect(scanner.pipeline).to eq(pipeline)
          end
        end

        context "with non-default branch pipeline" do
          subject(:scanner) { described_class.scanner_for_pipeline(project, pipeline_2) }

          let_it_be(:pipeline_2) do
            create(:ee_ci_pipeline, :with_cyclonedx_report, project: project, ref: "license_scanning_branch")
          end

          it "returns an sbom scanner" do
            is_expected.to be_a_kind_of(::Gitlab::LicenseScanning::SbomScanner)
          end

          it "returns a pipeline" do
            expect(scanner.pipeline).to eq(pipeline_2)
          end
        end
      end

      context "when pipeline has license scanning and sbom reports" do
        let_it_be(:pipeline) do
          create(:ee_ci_pipeline, :with_license_scanning_report, :with_cyclonedx_report, project: project)
        end

        it "returns an artifact scanner" do
          is_expected.to be_a_kind_of(::Gitlab::LicenseScanning::ArtifactScanner)
        end

        it "returns a pipeline" do
          expect(scanner.pipeline).to eq(pipeline)
        end
      end
    end
  end
end
